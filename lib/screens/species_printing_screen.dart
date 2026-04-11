import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_brother/printer_info.dart' as brother;
import '../models/species.dart';
import '../services/service_locator.dart';
import '../services/printing_service.dart';

class SpeciesPrintingScreen extends StatefulWidget {
  final Species species;

  const SpeciesPrintingScreen({super.key, required this.species});

  @override
  State<SpeciesPrintingScreen> createState() => _SpeciesPrintingScreenState();
}

class _SpeciesPrintingScreenState extends State<SpeciesPrintingScreen> {
  final _noteController = TextEditingController();

  String _printerMac = '';
  String _printerName = '';
  int _printerModelId = -1;

  LabelLayout _layout = LabelLayout.simple;
  int _tapeWidthMm = 12;

  bool _isPrinting = false;
  bool _isDiscovering = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _printerMac = prefs.getString('printer_mac') ?? '';
      _printerName = prefs.getString('printer_name') ?? '';
      _printerModelId = prefs.getInt('printer_model_id') ?? -1;
    });
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
    if (_printerMac.isEmpty) {
      await _discover();
      if (_printerMac.isEmpty) return;
    }

    final model = _printerModelId >= 0
        ? brother.Model.valueFromID(_printerModelId)
        : brother.Model.PT_P910BT;

    setState(() {
      _isPrinting = true;
      _statusMessage = 'Printing ${widget.species.name}...';
    });

    try {
      final success = await locator.print.printSpecies(
        widget.species,
        _printerMac,
        model,
        note: _noteController.text,
        layout: _layout,
        tapeWidthMm: _tapeWidthMm,
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

  @override
  Widget build(BuildContext context) {
    final s = widget.species;
    final hasPrinter = _printerMac.isNotEmpty;

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
                  // Species info
                  Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(s.id, style: const TextStyle(color: Colors.yellow, fontSize: 14)),
                          if (s.latinName != null && s.latinName!.isNotEmpty)
                            Text(s.latinName!, style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
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

                  // Layout selection
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<LabelLayout>(
                          initialValue: _layout,
                          dropdownColor: Colors.grey[800],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Layout',
                            labelStyle: TextStyle(color: Colors.yellow),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                          ),
                          items: const [
                            DropdownMenuItem(value: LabelLayout.simple, child: Text('Simple')),
                            DropdownMenuItem(value: LabelLayout.flag, child: Text('Flag')),
                          ],
                          onChanged: (v) => setState(() => _layout = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _tapeWidthMm,
                          dropdownColor: Colors.grey[800],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Tape',
                            labelStyle: TextStyle(color: Colors.yellow),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 6, child: Text('6mm')),
                            DropdownMenuItem(value: 9, child: Text('9mm')),
                            DropdownMenuItem(value: 12, child: Text('12mm')),
                            DropdownMenuItem(value: 18, child: Text('18mm')),
                            DropdownMenuItem(value: 24, child: Text('24mm')),
                            DropdownMenuItem(value: 36, child: Text('36mm')),
                          ],
                          onChanged: (v) => setState(() => _tapeWidthMm = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Note input
                  TextField(
                    controller: _noteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'NOTE (optional, per-label)',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'e.g. Cerveny, roubovanec...',
                      hintStyle: TextStyle(color: Colors.white24),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
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

          // Print button — always at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 64,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPrinting ? null : _print,
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
