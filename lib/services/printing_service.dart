import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart' as brother;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:qr/qr.dart';
import '../models/species.dart';

/// What content to include on the label.
class LabelContent {
  final bool qr;
  final bool note;
  final bool flag; // mirror for cable wrapping
  final String noteText;

  const LabelContent({
    this.qr = true,
    this.note = false,
    this.flag = false,
    this.noteText = '',
  });
}

abstract class PrintingService {
  Future<void> initialize();
  Future<List<DiscoveredPrinter>> discoverPrinters();
  List<DiscoveredPrinter> get lastDiscoveredPrinters;
  Future<ui.Image> generateLabel(Species species, int tapeWidthMm, LabelContent content);
  Future<bool> printSpecies(Species species, String macAddress, brother.Model model, {
    int tapeWidthMm = 12,
    LabelContent content = const LabelContent(),
  });
}

class DiscoveredPrinter {
  final String name;
  final String macAddress;
  final brother.Model model;

  DiscoveredPrinter({required this.name, required this.macAddress, required this.model});
}

/// Maps Bluetooth device name prefixes to the closest Model enum value.
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

const _extraBtFilterNames = ['PT-E920BT'];

/// PT-E920BT prints at 360 DPI.
const _dpi = 360;
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
          await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();
        }
      }

      final List<String> ptModels = [
        for (final m in brother.Model.getValues())
          if (m.getName().startsWith('PT-')) m.getName(),
        ..._extraBtFilterNames,
      ];

      final List<brother.BluetoothPrinter> btPrinters = await printer.getBluetoothPrinters(ptModels);
      debugPrint("PrintingService: Found ${btPrinters.length} BT devices");

      final List<brother.BLEPrinter> blePrinters = await printer.getBLEPrinters(10000);
      debugPrint("PrintingService: Found ${blePrinters.length} BLE devices");

      final List<brother.NetPrinter> netPrinters = await printer.getNetPrinters(ptModels);
      debugPrint("PrintingService: Found ${netPrinters.length} NET devices");

      final List<DiscoveredPrinter> results = [];
      for (var p in btPrinters) {
        final name = p.modelName ?? 'Brother Printer (BT)';
        results.add(DiscoveredPrinter(name: name, macAddress: p.macAddress ?? '', model: _modelFromName(name)));
      }
      for (var p in blePrinters) {
        final name = p.localName ?? 'Brother Printer (BLE)';
        results.add(DiscoveredPrinter(name: name, macAddress: p.localName ?? '', model: _modelFromName(name)));
      }
      for (var p in netPrinters) {
        final name = p.modelName ?? 'Brother Printer (WiFi)';
        results.add(DiscoveredPrinter(name: name, macAddress: p.ipAddress ?? '', model: _modelFromName(name)));
      }

      _discoveredPrinters = results;
      return results;
    } catch (e, stack) {
      debugPrint("PrintingService: Discovery error: $e\n$stack");
      rethrow;
    }
  }

  @override
  Future<bool> printSpecies(Species species, String macAddress, brother.Model model, {
    int tapeWidthMm = 12,
    LabelContent content = const LabelContent(),
  }) async {
    try {
      final printer = brother.Printer();
      final printInfo = brother.PrinterInfo();

      printInfo.printerModel = model;
      printInfo.isAutoCut = true;
      printInfo.isCutAtEnd = true;

      final labelIndex = _labelIndexForTapeWidth(tapeWidthMm);
      if (labelIndex >= 0) printInfo.labelNameIndex = labelIndex;

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

      debugPrint("PrintingService: Generating label (${tapeWidthMm}mm, qr=${content.qr}, note=${content.note}, flag=${content.flag})");
      final image = await generateLabel(species, tapeWidthMm, content);

      debugPrint("PrintingService: Printing image ${image.width}x${image.height}...");
      final status = await printer.printImage(image);
      debugPrint("PrintingService: Result: ${status.errorCode.getName()}");

      return status.errorCode == brother.ErrorCode.ERROR_NONE;
    } catch (e) {
      debugPrint("PrintingService: Print error: $e");
      return false;
    }
  }

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

  // ── Label generation ──────────────────────────────────────────

  @override
  Future<ui.Image> generateLabel(Species species, int tapeWidthMm, LabelContent content) async {
    final margin = _mmToPx(2);
    final tapeH = _mmToPx(tapeWidthMm.toDouble());
    final printH = tapeH - margin * 2;

    // Build one half of the label
    final halfImage = _buildHalf(species, printH, margin, content);

    if (!content.flag) return halfImage;

    // Flag: [half] | fold | [half mirrored]
    return _buildFlag(halfImage, printH, margin);
  }

  /// Build one label panel: optional QR + NAME + optional NOTE
  ui.Image _buildHalf(Species species, int printH, int margin, LabelContent content) {
    final showQr = content.qr;
    final showNote = content.note && content.noteText.isNotEmpty;

    final qrSize = showQr ? printH : 0;
    final gap = showQr ? _mmToPx(2) : 0;

    // Text area width scales with tape height for proportional labels
    final textAreaW = _mmToPx(printH > _mmToPx(15) ? 40 : 30).toDouble();
    final totalW = margin + qrSize + gap + textAreaW.toInt() + margin;
    final totalH = printH + margin * 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // White background
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF));

    // QR code
    if (showQr) {
      _drawQrCode(canvas, species.id, margin.toDouble(), margin.toDouble(), qrSize.toDouble());
    }

    // Text origin
    final textX = (margin + qrSize + gap).toDouble();

    if (showNote) {
      // NAME on top ~60%, NOTE below ~35%
      final nameFontSize = _fontSize(printH, 0.35);
      final noteFontSize = _fontSize(printH, 0.25);
      _drawText(canvas, species.name, textX, margin.toDouble(),
          textAreaW, printH * 0.6, nameFontSize, bold: true);
      _drawText(canvas, content.noteText, textX, margin + printH * 0.65,
          textAreaW, printH * 0.35, noteFontSize);
    } else {
      // NAME centered vertically
      final nameFontSize = _fontSize(printH, 0.45);
      _drawText(canvas, species.name, textX, margin.toDouble(),
          textAreaW, printH.toDouble(), nameFontSize, bold: true, center: true);
    }

    final picture = recorder.endRecording();
    return picture.toImageSync(totalW, totalH);
  }

  /// Build a flag label: [half] | fold line | [half mirrored]
  Future<ui.Image> _buildFlag(ui.Image half, int printH, int margin) async {
    final halfW = half.width;
    final foldW = _mmToPx(3);
    final totalW = halfW * 2 + foldW;
    final totalH = printH + margin * 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // White background
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF));

    // Left half
    canvas.drawImage(half, ui.Offset.zero, ui.Paint());

    // Fold line (dashed)
    final foldX = halfW + foldW / 2;
    final dashPaint = ui.Paint()
      ..color = const ui.Color(0xFF888888)
      ..strokeWidth = 1;
    for (double y = 0; y < totalH; y += 6) {
      canvas.drawLine(ui.Offset(foldX.toDouble(), y), ui.Offset(foldX.toDouble(), y + 3), dashPaint);
    }

    // Right half (mirrored horizontally)
    canvas.save();
    canvas.translate(totalW.toDouble(), 0);
    canvas.scale(-1, 1);
    canvas.drawImage(half, ui.Offset.zero, ui.Paint());
    canvas.restore();

    final picture = recorder.endRecording();
    return picture.toImage(totalW, totalH);
  }

  double _fontSize(int printH, double ratio) => (printH * ratio).clamp(12, 72).toDouble();

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
