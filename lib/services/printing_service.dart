import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart' as brother;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:qr/qr.dart';
import '../models/species.dart';

/// Label layout types matching the two real-world use cases.
enum LabelLayout {
  /// Simple label: NAME + NOTE + QR code side by side
  simple,
  /// Flag label: QR | NAME | fold | NAME | QR
  flag,
}

abstract class PrintingService {
  Future<void> initialize();
  Future<List<DiscoveredPrinter>> discoverPrinters();
  List<DiscoveredPrinter> get lastDiscoveredPrinters;
  Future<bool> printSpecies(Species species, String macAddress, brother.Model model, {
    String note = '',
    LabelLayout layout = LabelLayout.simple,
    int tapeWidthMm = 12,
  });
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
  if (upper.startsWith('PT-E920') || upper.startsWith('PT_E920')) {
    return brother.Model.PT_P910BT;
  }
  return brother.Model.PT_E850TKW;
}

/// Extra model name strings for BT discovery that aren't in the Model enum.
const _extraBtFilterNames = ['PT-E920BT'];

/// PT-E920BT prints at 360 DPI.
const _dpi = 360;

/// Convert mm to pixels at printer DPI.
int _mmToPx(double mm) => (mm * _dpi / 25.4).round();

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

      if (Platform.isAndroid) {
        if (!await Permission.bluetoothScan.isGranted ||
            !await Permission.bluetoothConnect.isGranted ||
            !await Permission.location.isGranted) {
          debugPrint("PrintingService: Permissions not fully granted, requesting...");
          await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();
        }
      }

      final List<String> ptModels = [
        for (final m in brother.Model.getValues())
          if (m.getName().startsWith('PT-')) m.getName(),
        ..._extraBtFilterNames,
      ];

      debugPrint("PrintingService: Calling getBluetoothPrinters...");
      final List<brother.BluetoothPrinter> btPrinters = await printer.getBluetoothPrinters(ptModels);
      debugPrint("PrintingService: Found ${btPrinters.length} bluetooth devices");

      debugPrint("PrintingService: Calling getBLEPrinters (10s timeout)...");
      final List<brother.BLEPrinter> blePrinters = await printer.getBLEPrinters(10000);
      debugPrint("PrintingService: Found ${blePrinters.length} BLE devices");

      debugPrint("PrintingService: Calling getNetPrinters...");
      final List<brother.NetPrinter> netPrinters = await printer.getNetPrinters(ptModels);
      debugPrint("PrintingService: Found ${netPrinters.length} network devices");

      final List<DiscoveredPrinter> results = [];

      for (var p in btPrinters) {
        final name = p.modelName ?? 'Brother Printer (BT)';
        debugPrint("PrintingService: BT Device: $name at ${p.macAddress}");
        results.add(DiscoveredPrinter(name: name, macAddress: p.macAddress ?? '', model: _modelFromName(name)));
      }
      for (var p in blePrinters) {
        final name = p.localName ?? 'Brother Printer (BLE)';
        debugPrint("PrintingService: BLE Device: $name");
        results.add(DiscoveredPrinter(name: name, macAddress: p.localName ?? '', model: _modelFromName(name)));
      }
      for (var p in netPrinters) {
        final name = p.modelName ?? 'Brother Printer (WiFi)';
        debugPrint("PrintingService: NET Device: $name at ${p.ipAddress}");
        results.add(DiscoveredPrinter(name: name, macAddress: p.ipAddress ?? '', model: _modelFromName(name)));
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
  Future<bool> printSpecies(Species species, String macAddress, brother.Model model, {
    String note = '',
    LabelLayout layout = LabelLayout.simple,
    int tapeWidthMm = 12,
  }) async {
    try {
      final printer = brother.Printer();
      final printInfo = brother.PrinterInfo();

      printInfo.printerModel = model;
      printInfo.isAutoCut = true;
      printInfo.isCutAtEnd = true;

      // Set label width
      final labelIndex = _labelIndexForTapeWidth(tapeWidthMm);
      if (labelIndex >= 0) printInfo.labelNameIndex = labelIndex;

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

      // Generate label image
      debugPrint("PrintingService: Generating label image (${layout.name}, ${tapeWidthMm}mm)");
      final image = await _generateLabel(species, note: note, layout: layout, tapeWidthMm: tapeWidthMm);

      // Print
      debugPrint("PrintingService: Sending image to printer...");
      final status = await printer.printImage(image);
      debugPrint("PrintingService: Print result: ${status.errorCode.getName()}");

      return status.errorCode == brother.ErrorCode.ERROR_NONE;
    } catch (e) {
      debugPrint("PrintingService: Print error: $e");
      return false;
    }
  }

  /// Returns the label name index for a given tape width in mm.
  int _labelIndexForTapeWidth(int mm) {
    switch (mm) {
      case 6:  return PT.W6.getId();
      case 9:  return PT.W9.getId();
      case 12: return PT.W12.getId();
      case 18: return PT.W18.getId();
      case 24: return PT.W24.getId();
      case 36: return PT.W36.getId();
      default: return -1;
    }
  }

  /// Generate a label image for the given species.
  Future<ui.Image> _generateLabel(Species species, {
    String note = '',
    LabelLayout layout = LabelLayout.simple,
    int tapeWidthMm = 12,
  }) async {
    final tapeH = _mmToPx(tapeWidthMm.toDouble());
    // Margins ~2mm on each side
    final margin = _mmToPx(2);
    final printH = tapeH - margin * 2;

    switch (layout) {
      case LabelLayout.simple:
        return _generateSimpleLabel(species, printH, margin, note: note);
      case LabelLayout.flag:
        return _generateFlagLabel(species, printH, margin, note: note);
    }
  }

  /// Simple label: [QR] [NAME / NOTE]
  Future<ui.Image> _generateSimpleLabel(Species species, int printH, int margin, {String note = ''}) async {
    final qrSize = printH;
    final textAreaW = _mmToPx(40); // ~40mm for text
    final totalW = margin + qrSize + margin + textAreaW + margin;
    final totalH = printH + margin * 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // White background
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF));

    // QR code
    _drawQrCode(canvas, species.id, margin.toDouble(), margin.toDouble(), qrSize.toDouble());

    // Name text
    final nameX = margin + qrSize + margin;
    final nameFontSize = (printH * 0.35).clamp(14, 60).toDouble();
    _drawText(canvas, species.name, nameX.toDouble(), margin.toDouble(),
        textAreaW.toDouble(), printH * 0.55, nameFontSize, bold: true);

    // Note text (smaller, below name)
    if (note.isNotEmpty) {
      final noteFontSize = (printH * 0.25).clamp(10, 40).toDouble();
      _drawText(canvas, note, nameX.toDouble(), margin + printH * 0.6,
          textAreaW.toDouble(), printH * 0.35, noteFontSize);
    }

    final picture = recorder.endRecording();
    return picture.toImage(totalW, totalH);
  }

  /// Flag label: [QR] [NAME] | fold line | [NAME] [QR]
  Future<ui.Image> _generateFlagLabel(Species species, int printH, int margin, {String note = ''}) async {
    final qrSize = printH;
    final textAreaW = _mmToPx(30); // ~30mm per text area
    final halfW = margin + qrSize + _mmToPx(2) + textAreaW + margin;
    final foldW = _mmToPx(3); // ~3mm fold gap
    final totalW = halfW * 2 + foldW;
    final totalH = printH + margin * 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // White background
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF));

    final nameFontSize = (printH * 0.35).clamp(14, 60).toDouble();

    // Left side: QR | NAME
    _drawQrCode(canvas, species.id, margin.toDouble(), margin.toDouble(), qrSize.toDouble());
    final textX1 = margin + qrSize + _mmToPx(2);
    _drawText(canvas, species.name, textX1.toDouble(), margin.toDouble(),
        textAreaW.toDouble(), printH.toDouble(), nameFontSize, bold: true, center: true);

    // Fold line (dashed)
    final foldX = halfW.toDouble();
    final dashPaint = ui.Paint()
      ..color = const ui.Color(0xFF888888)
      ..strokeWidth = 1;
    for (double y = 0; y < totalH; y += 6) {
      canvas.drawLine(ui.Offset(foldX + foldW / 2, y), ui.Offset(foldX + foldW / 2, y + 3), dashPaint);
    }

    // Right side: NAME | QR
    final rightStart = halfW + foldW;
    final textX2 = rightStart + margin;
    _drawText(canvas, species.name, textX2.toDouble(), margin.toDouble(),
        textAreaW.toDouble(), printH.toDouble(), nameFontSize, bold: true, center: true);
    final qrX2 = textX2 + textAreaW + _mmToPx(2);
    _drawQrCode(canvas, species.id, qrX2.toDouble(), margin.toDouble(), qrSize.toDouble());

    final picture = recorder.endRecording();
    return picture.toImage(totalW, totalH);
  }

  /// Draw a QR code on the canvas.
  void _drawQrCode(ui.Canvas canvas, String data, double x, double y, double size) {
    final qrCode = QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M);
    final qr = QrImage(qrCode);
    final moduleCount = qr.moduleCount;
    final cellSize = size / moduleCount;

    final paint = ui.Paint()..color = const ui.Color(0xFF000000);
    for (int row = 0; row < moduleCount; row++) {
      for (int col = 0; col < moduleCount; col++) {
        if (qr.isDark(row, col)) {
          canvas.drawRect(
            ui.Rect.fromLTWH(x + col * cellSize, y + row * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  /// Draw text on the canvas, fitting within the given bounds.
  void _drawText(ui.Canvas canvas, String text, double x, double y,
      double maxW, double maxH, double fontSize,
      {bool bold = false, bool center = false}) {
    final style = ui.TextStyle(
      color: const ui.Color(0xFF000000),
      fontSize: fontSize,
      fontWeight: bold ? ui.FontWeight.bold : ui.FontWeight.normal,
    );
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: center ? ui.TextAlign.center : ui.TextAlign.left,
      maxLines: 3,
      ellipsis: '...',
    ))
      ..pushStyle(style)
      ..addText(text);

    final paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxW));
    canvas.drawParagraph(paragraph, ui.Offset(x, center ? y + (maxH - paragraph.height) / 2 : y));
  }
}
