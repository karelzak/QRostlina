import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart' as brother;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/species.dart';
import '../models/print_template.dart';

abstract class PrintingService {
  Future<void> initialize();
  Future<List<DiscoveredPrinter>> discoverPrinters();
  List<DiscoveredPrinter> get lastDiscoveredPrinters;
  Future<bool> printSpecies(Species species, String templatePath, String macAddress, brother.Model model, {String note = ''});
  Future<String?> validateConnection(String macAddress, brother.Model model);

  // Template management
  Future<List<PrintTemplate>> getTemplates();
  Future<PrintTemplate> addTemplate(String sourceFilePath, String name, String tapeSize);
  Future<void> deleteTemplate(String templateId);
}

class DiscoveredPrinter {
  final String name;
  final String macAddress;
  final brother.Model model;

  DiscoveredPrinter({required this.name, required this.macAddress, required this.model});
}

/// Maps Bluetooth device name prefixes to the closest Model enum value.
/// PT-E920BT is not in another_brother v2.2.4; PT_P910BT is the closest
/// compatible model (same 36mm tape, BT, PT label printer series).
brother.Model _modelFromName(String deviceName) {
  final upper = deviceName.toUpperCase();
  for (final model in brother.Model.getValues()) {
    final modelName = model.getName().toUpperCase();
    if (upper.startsWith(modelName)) return model;
  }
  // PT-E920BT not in enum — map to PT_P910BT (closest 36mm BT PT printer)
  if (upper.startsWith('PT-E920') || upper.startsWith('PT_E920')) {
    return brother.Model.PT_P910BT;
  }
  return brother.Model.PT_E850TKW; // safe fallback for unknown PT printers
}

/// Extra model name strings for BT discovery that aren't in the Model enum.
const _extraBtFilterNames = ['PT-E920BT'];

class BrotherPrintingService implements PrintingService {
  List<DiscoveredPrinter> _discoveredPrinters = [];

  @override
  List<DiscoveredPrinter> get lastDiscoveredPrinters => _discoveredPrinters;

  @override
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      debugPrint("PrintingService: Requesting permissions...");
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      debugPrint("PrintingService: Permission statuses: $statuses");
    }
  }

  @override
  Future<List<DiscoveredPrinter>> discoverPrinters() async {
    try {
      debugPrint("PrintingService: Starting discovery...");
      final printer = brother.Printer();
      
      // Ensure permissions are granted before discovery
      if (Platform.isAndroid) {
        if (!await Permission.bluetoothScan.isGranted || 
            !await Permission.bluetoothConnect.isGranted ||
            !await Permission.location.isGranted) {
           debugPrint("PrintingService: Permissions not fully granted, requesting...");
           await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();
        }
      }

      // Build filter list from all known PT models + extra names not yet in enum
      final List<String> ptModels = [
        for (final m in brother.Model.getValues())
          if (m.getName().startsWith('PT-')) m.getName(),
        ..._extraBtFilterNames,
      ];

      // 1. Try Bluetooth Search (Classic)
      debugPrint("PrintingService: Calling getBluetoothPrinters (matching common PT models)...");
      final List<brother.BluetoothPrinter> btPrinters = await printer.getBluetoothPrinters(ptModels);
      debugPrint("PrintingService: Found ${btPrinters.length} bluetooth devices");

      // 2. Try BLE Search (Bluetooth Low Energy)
      debugPrint("PrintingService: Calling getBLEPrinters (10s timeout)...");
      final List<brother.BLEPrinter> blePrinters = await printer.getBLEPrinters(10000);
      debugPrint("PrintingService: Found ${blePrinters.length} BLE devices");

      // 3. Try Network Search (as Wi-Fi Direct might be active)
      debugPrint("PrintingService: Calling getNetPrinters...");
      final List<brother.NetPrinter> netPrinters = await printer.getNetPrinters(ptModels);
      debugPrint("PrintingService: Found ${netPrinters.length} network devices");

      final List<DiscoveredPrinter> results = [];

      for (var p in btPrinters) {
        final name = p.modelName ?? 'Brother Printer (BT)';
        debugPrint("PrintingService: BT Device: $name at ${p.macAddress}");
        results.add(DiscoveredPrinter(
          name: name,
          macAddress: p.macAddress ?? '',
          model: _modelFromName(name),
        ));
      }

      for (var p in blePrinters) {
        final name = p.localName ?? 'Brother Printer (BLE)';
        debugPrint("PrintingService: BLE Device: $name");
        results.add(DiscoveredPrinter(
          name: name,
          macAddress: p.localName ?? '', // For BLE, localName is used for connection
          model: _modelFromName(name),
        ));
      }

      for (var p in netPrinters) {
        final name = p.modelName ?? 'Brother Printer (WiFi)';
        debugPrint("PrintingService: NET Device: $name at ${p.ipAddress}");
        results.add(DiscoveredPrinter(
          name: name,
          macAddress: p.ipAddress ?? '',
          model: _modelFromName(name),
        ));
      }

      _discoveredPrinters = results;
      return results;
    } catch (e, stack) {
      debugPrint("PrintingService: Discovery error: $e");
      debugPrint("PrintingService: Stacktrace: $stack");
      rethrow;
    }
  }

  @override
  Future<bool> printSpecies(Species species, String templatePath, String macAddress, brother.Model model, {String note = ''}) async {
    try {
      final printer = brother.Printer();
      final printInfo = brother.PrinterInfo();

      printInfo.printerModel = model;

      // Determine port from address format
      bool isMac = macAddress.contains(':') || (macAddress.length == 12 && !macAddress.contains('-'));

      if (isMac) {
        printInfo.port = brother.Port.BLUETOOTH;
        printInfo.macAddress = macAddress;
      } else if (macAddress.contains('.')) {
        printInfo.port = brother.Port.NET;
        printInfo.ipAddress = macAddress;
      } else {
        printInfo.port = brother.Port.BLE;
        printInfo.setLocalName(macAddress);
      }

      await printer.setPrinterInfo(printInfo);

      // Transfer template to printer
      debugPrint("PrintingService: Transferring template $templatePath");
      final transferStatus = await printer.transfer(templatePath);
      debugPrint("PrintingService: Transfer result: ${transferStatus.errorCode.getName()}");

      // Start P-touch Template mode (key 1, UTF-8)
      debugPrint("PrintingService: Starting PTT Print");
      bool started = await printer.startPTTPrint(1, "UTF-8");
      if (!started) {
        debugPrint("PrintingService: Failed to start PTT Print session");
        return false;
      }

      // Replace all well-known object names (no-op if object doesn't exist in template)
      // Text: species name
      await printer.replaceTextName(species.name, "NAME");
      await printer.replaceTextName(species.name, "NAME1");
      await printer.replaceTextName(species.name, "NAME2");
      // QR code: species ID
      await printer.replaceTextName(species.id, "QR");
      await printer.replaceTextName(species.id, "QR1");
      await printer.replaceTextName(species.id, "QR2");
      // Plain text ID
      await printer.replaceTextName(species.id, "ID");
      // User-provided per-label note
      if (note.isNotEmpty) {
        await printer.replaceTextName(note, "NOTE");
      }

      final printStatus = await printer.flushPTTPrint();
      debugPrint("PrintingService: Print finished with code: ${printStatus.errorCode.getName()}");

      return printStatus.errorCode == brother.ErrorCode.ERROR_NONE;
    } catch (e) {
      debugPrint("PrintingService: Print error: $e");
      return false;
    }
  }

  @override
  Future<String?> validateConnection(String macAddress, brother.Model model) async {
    try {
      debugPrint("PrintingService: Validating connection to $macAddress...");

      // Determine port type from address format
      final brother.Port port;
      final bool isMac = macAddress.contains(':') || (macAddress.length == 12 && !macAddress.contains('-'));
      if (isMac) {
        port = brother.Port.BLUETOOTH;
      } else if (macAddress.contains('.')) {
        port = brother.Port.NET;
      } else {
        port = brother.Port.BLE;
      }

      // Try the hint model first, then PT_P910BT (for E920BT), then other PT models
      final List<brother.Model> candidates = [
        model,
        _modelFromName(macAddress), // in case macAddress is a BLE local name
        brother.Model.PT_P910BT,
        brother.Model.PT_E850TKW,
        brother.Model.PT_P950NW,
        brother.Model.PT_P900W,
        brother.Model.PT_D610BT,
        brother.Model.PT_D460BT,
        brother.Model.PT_P710BT,
        brother.Model.PT_E550W,
        brother.Model.PT_P750W,
        brother.Model.PT_D800W,
      ];

      // Deduplicate while preserving order
      final seen = <int>{};
      final uniqueCandidates = candidates.where((m) => seen.add(m.getId())).toList();

      for (var testModel in uniqueCandidates) {
        final modelName = testModel.getName();
        debugPrint("--------------------------------------------------");
        debugPrint("TESTING MODEL: $modelName on port ${port.getName()}");

        await Future.delayed(const Duration(milliseconds: 500));

        final printer = brother.Printer();
        final printInfo = brother.PrinterInfo();
        printInfo.printerModel = testModel;
        printInfo.port = port;

        if (port == brother.Port.BLUETOOTH) {
          printInfo.macAddress = macAddress;
        } else if (port == brother.Port.NET) {
          printInfo.ipAddress = macAddress;
        } else {
          printInfo.setLocalName(macAddress);
        }

        await printer.setPrinterInfo(printInfo);
        final status = await printer.getPrinterStatus();

        if (status.errorCode == brother.ErrorCode.ERROR_NONE) {
          debugPrint("PrintingService: SUCCESS! Model $modelName on port ${port.getName()}");
          return "Connected: OK ($modelName)";
        } else {
          debugPrint("PrintingService: Result: ${status.errorCode.getName()}");
        }
      }

      return "Model not identified (All PT models failed on ${port.getName()})";
    } catch (e) {
      debugPrint("PrintingService: Validation error: $e");
      return "Connection Failed";
    }
  }

  // --- Template management ---

  Future<Directory> _templatesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'templates'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _metadataFile() async {
    final dir = await _templatesDir();
    return File(p.join(dir.path, 'templates.json'));
  }

  @override
  Future<List<PrintTemplate>> getTemplates() async {
    final file = await _metadataFile();
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    final List<dynamic> list = jsonDecode(content);
    return list.map((e) => PrintTemplate.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveTemplates(List<PrintTemplate> templates) async {
    final file = await _metadataFile();
    await file.writeAsString(jsonEncode(templates.map((t) => t.toMap()).toList()));
  }

  @override
  Future<PrintTemplate> addTemplate(String sourceFilePath, String name, String tapeSize) async {
    final dir = await _templatesDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = p.extension(sourceFilePath).toLowerCase();
    final destPath = p.join(dir.path, '$id$ext');

    await File(sourceFilePath).copy(destPath);

    final template = PrintTemplate(
      id: id,
      name: name,
      localPath: destPath,
      tapeSize: tapeSize,
    );

    final templates = await getTemplates();
    templates.add(template);
    await _saveTemplates(templates);

    debugPrint("PrintingService: Added template '$name' -> $destPath");
    return template;
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    final templates = await getTemplates();
    final template = templates.where((t) => t.id == templateId).firstOrNull;
    if (template != null) {
      final file = File(template.localPath);
      if (await file.exists()) await file.delete();
      templates.removeWhere((t) => t.id == templateId);
      await _saveTemplates(templates);
      debugPrint("PrintingService: Deleted template '${template.name}'");
    }
  }
}
