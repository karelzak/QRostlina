import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_brother/printer_info.dart' as brother;
import '../services/service_locator.dart';
import '../services/printing_service.dart';

class PrintingScreen extends StatefulWidget {
  /// Data for QR code. In generic mode, QR encodes the label text.
  final String? qrData;

  /// Text always printed on the label (e.g., species name, bed/crate ID).
  final String? fixedText;

  /// Optional text the user can toggle on/off via a "Label" chip (e.g., bed name).
  final String? toggleableLabel;

  /// Entity name for info card. Null = generic mode.
  final String? infoName;

  /// Entity ID for info card.
  final String? infoId;

  /// Extra info line (e.g., latin name, bed row, crate type).
  final String? infoSubtitle;

  const PrintingScreen({
    super.key,
    this.qrData,
    this.fixedText,
    this.toggleableLabel,
    this.infoName,
    this.infoId,
    this.infoSubtitle,
  });

  @override
  State<PrintingScreen> createState() => _PrintingScreenState();
}

class _PrintingScreenState extends State<PrintingScreen> {
  final _noteController = TextEditingController();
  final _labelTextController = TextEditingController();

  String _printerMac = '';
  String _printerName = '';
  int _printerModelId = -1;

  int _tapeWidthMm = 12;
  bool _includeQr = true;
  bool _includeNote = false;
  bool _includeLabel = true;
  bool _flagMode = false;

  bool _isPrinting = false;
  bool _isDiscovering = false;
  String _statusMessage = '';
  ui.Image? _previewImage;

  bool get _isGeneric => widget.infoName == null;
  bool get _hasToggleableLabel => widget.toggleableLabel != null && widget.toggleableLabel!.isNotEmpty;

  String get _effectiveLabelText {
    if (_isGeneric) return _labelTextController.text;
    final parts = <String>[];
    if (widget.fixedText != null && widget.fixedText!.isNotEmpty) {
      parts.add(widget.fixedText!);
    }
    if (_includeLabel && _hasToggleableLabel) {
      parts.add(widget.toggleableLabel!);
    }
    return parts.join('\n');
  }

  String? get _effectiveQrData => _isGeneric
      ? (_labelTextController.text.isNotEmpty ? _labelTextController.text : null)
      : widget.qrData;

  @override
  void initState() {
    super.initState();
    _load();
    _noteController.addListener(_updatePreview);
    if (_isGeneric) {
      _labelTextController.addListener(_updatePreview);
    }
    _updatePreview();
  }

  @override
  void dispose() {
    _noteController.removeListener(_updatePreview);
    if (_isGeneric) {
      _labelTextController.removeListener(_updatePreview);
    }
    _noteController.dispose();
    _labelTextController.dispose();
    _previewImage?.dispose();
    super.dispose();
  }

  void _updatePreview() async {
    final text = _effectiveLabelText;
    if (text.isEmpty) {
      if (!mounted) return;
      setState(() {
        _previewImage?.dispose();
        _previewImage = null;
      });
      return;
    }
    final content = LabelContent(
      qr: _includeQr && _qrAllowed,
      note: _includeNote,
      flag: _flagMode,
      noteText: _noteController.text,
    );
    final image = await locator.print.generateLabel(
        _effectiveQrData, text, _tapeWidthMm, content);
    if (!mounted) return;
    setState(() {
      _previewImage?.dispose();
      _previewImage = image;
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _printerMac = prefs.getString('printer_mac') ?? '';
      _printerName = prefs.getString('printer_name') ?? '';
      _printerModelId = prefs.getInt('printer_model_id') ?? -1;
      _tapeWidthMm = prefs.getInt('label_tape_width') ?? 12;
      _includeQr = prefs.getBool('label_include_qr') ?? true;
      _includeNote = prefs.getBool('label_include_note') ?? false;
      _includeLabel = prefs.getBool('label_include_label') ?? true;
      _flagMode = prefs.getBool('label_flag_mode') ?? false;
    });
    _updatePreview();
  }

  Future<void> _saveLabelSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('label_tape_width', _tapeWidthMm);
    await prefs.setBool('label_include_qr', _includeQr);
    await prefs.setBool('label_include_note', _includeNote);
    await prefs.setBool('label_include_label', _includeLabel);
    await prefs.setBool('label_flag_mode', _flagMode);
  }

  Future<void> _discover() async {
    setState(() {
      _isDiscovering = true;
      _statusMessage = 'Discovering printers...';
    });

    try {
      await locator.print.discoverPrinters();
      final printers = locator.print.lastDiscoveredPrinters;
      if (printers.isNotEmpty) {
        final p = printers.first;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('printer_mac', p.macAddress);
        await prefs.setString('printer_name', p.name);
        await prefs.setInt('printer_model_id', p.model.getId());
        setState(() {
          _printerMac = p.macAddress;
          _printerName = p.name;
          _printerModelId = p.model.getId();
          _isDiscovering = false;
          _statusMessage = 'Found: ${p.name}';
        });
      } else {
        setState(() {
          _isDiscovering = false;
          _statusMessage = 'No printers found';
        });
      }
    } catch (e) {
      setState(() {
        _isDiscovering = false;
        _statusMessage = 'Discovery failed: $e';
      });
    }
  }

  Future<void> _print() async {
    final text = _effectiveLabelText;
    if (text.isEmpty) return;

    if (_printerMac.isEmpty) {
      await _discover();
      if (_printerMac.isEmpty) return;
    }

    final model = _printerModelId >= 0
        ? brother.Model.valueFromID(_printerModelId)
        : brother.Model.PT_P910BT;

    setState(() {
      _isPrinting = true;
      _statusMessage = 'Printing...';
    });

    try {
      final success = await locator.print.printLabel(
        _effectiveQrData,
        text,
        _printerMac,
        model,
        tapeWidthMm: _tapeWidthMm,
        content: LabelContent(
          qr: _includeQr,
          note: _includeNote,
          flag: _flagMode,
          noteText: _noteController.text,
        ),
      );

      setState(() {
        _isPrinting = false;
        _statusMessage = success ? 'Printed OK' : 'Print failed';
      });
    } catch (e) {
      setState(() {
        _isPrinting = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  /// QR too small to scan on 12mm tape
  bool get _qrAllowed => _tapeWidthMm >= 18;

  @override
  Widget build(BuildContext context) {
    final hasPrinter = _printerMac.isNotEmpty;

    // Auto-disable QR when switching to small tape
    if (!_qrAllowed && _includeQr) {
      _includeQr = false;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('PRINT LABEL')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Entity info card OR generic text input
                  if (_isGeneric)
                    TextField(
                      controller: _labelTextController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Label text',
                        labelStyle: TextStyle(color: Colors.yellow),
                        hintText: 'Type text for the label...',
                        hintStyle: TextStyle(color: Colors.white24),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                      ),
                    )
                  else
                    Card(
                      color: Colors.grey[900],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.infoName!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(widget.infoId ?? '', style: const TextStyle(color: Colors.yellow, fontSize: 14)),
                            if (widget.infoSubtitle != null && widget.infoSubtitle!.isNotEmpty)
                              Text(widget.infoSubtitle!, style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Printer status
                  ListTile(
                    tileColor: Colors.grey[900],
                    leading: Icon(
                      hasPrinter ? Icons.print : Icons.print_disabled,
                      color: hasPrinter ? Colors.green : Colors.redAccent,
                    ),
                    title: Text(
                      hasPrinter ? _printerName : 'No printer',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: hasPrinter
                        ? Text(_printerMac, style: const TextStyle(color: Colors.white54, fontSize: 12))
                        : null,
                    trailing: IconButton(
                      icon: _isDiscovering
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.yellow))
                          : const Icon(Icons.bluetooth_searching, color: Colors.yellow),
                      onPressed: _isDiscovering ? null : _discover,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tape size
                  DropdownButtonFormField<int>(
                    initialValue: _tapeWidthMm,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tape size',
                      labelStyle: TextStyle(color: Colors.yellow),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 12, child: Text('12 mm')),
                      DropdownMenuItem(value: 18, child: Text('18 mm')),
                      DropdownMenuItem(value: 24, child: Text('24 mm')),
                      DropdownMenuItem(value: 36, child: Text('36 mm')),
                    ],
                    onChanged: (v) { setState(() => _tapeWidthMm = v!); _saveLabelSettings(); _updatePreview(); },
                  ),
                  const SizedBox(height: 12),

                  // Content toggles
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('QR Code'),
                        selected: _includeQr,
                        onSelected: _qrAllowed ? (v) { setState(() => _includeQr = v); _saveLabelSettings(); _updatePreview(); } : null,
                        selectedColor: Colors.yellow,
                        checkmarkColor: Colors.black,
                        disabledColor: Colors.grey[800],
                      ),
                      if (_hasToggleableLabel)
                        FilterChip(
                          label: const Text('Label'),
                          selected: _includeLabel,
                          onSelected: (v) { setState(() => _includeLabel = v); _saveLabelSettings(); _updatePreview(); },
                          selectedColor: Colors.yellow,
                          checkmarkColor: Colors.black,
                        ),
                      FilterChip(
                        label: const Text('Note'),
                        selected: _includeNote,
                        onSelected: (v) { setState(() => _includeNote = v); _saveLabelSettings(); _updatePreview(); },
                        selectedColor: Colors.yellow,
                        checkmarkColor: Colors.black,
                      ),
                      FilterChip(
                        label: const Text('Flag (2-sided)'),
                        selected: _flagMode,
                        onSelected: (v) { setState(() => _flagMode = v); _saveLabelSettings(); _updatePreview(); },
                        selectedColor: Colors.yellow,
                        checkmarkColor: Colors.black,
                      ),
                    ],
                  ),
                  if (!_qrAllowed)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('QR code disabled for 12mm (too small to scan)',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ),
                  const SizedBox(height: 12),

                  // Note input (only when Note is selected)
                  if (_includeNote)
                    TextField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Note text',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'e.g. Cerveny, roubovanec...',
                        hintStyle: TextStyle(color: Colors.white24),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                      ),
                    ),

                  // Preview
                  if (_previewImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.yellow, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: RawImage(image: _previewImage, filterQuality: FilterQuality.none),
                        ),
                      ),
                    ),

                  // Status
                  if (_statusMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 16),
                      color: Colors.black,
                      child: Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Print button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 64,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPrinting || _effectiveLabelText.isEmpty ? null : _print,
                icon: _isPrinting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                    : const Icon(Icons.print, size: 28),
                label: const Text('PRINT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
