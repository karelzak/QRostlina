import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_scanner_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _manualIdController = TextEditingController();

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        _handleCode(code);
        break; 
      }
    }
  }

  void _handleCode(String code) {
    final result = QRScannerService.parse(code);
    
    // Show a quick snackbar for feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanned: ${result.id} (${result.type.name})'),
        duration: const Duration(seconds: 2),
      ),
    );

    // TODO: Navigation to specific cards based on type
    debugPrint('Detected ${result.type}: ${result.id}');
  }

  @override
  Widget build(BuildContext context) {
    // mobile_scanner doesn't support Linux/Desktop yet, so we show a manual input for testing on Linux
    bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return Scaffold(
      appBar: AppBar(title: const Text('SCAN QR CODE')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: isMobile
                ? MobileScanner(
                    onDetect: _onDetect,
                  )
                : Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Text(
                        'Camera only available on Android/iOS.
Use manual input below for Linux testing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.black,
            child: Column(
              children: [
                TextField(
                  controller: _manualIdController,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    labelText: 'MANUAL ID ENTRY (e.g. S-001)',
                    labelStyle: const TextStyle(color: Colors.yellow),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.yellow),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.yellow, width: 2),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _handleCode(value.toUpperCase());
                      _manualIdController.clear();
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_manualIdController.text.isNotEmpty) {
                      _handleCode(_manualIdController.text.toUpperCase());
                      _manualIdController.clear();
                    }
                  },
                  child: const Text('SUBMIT ID'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
