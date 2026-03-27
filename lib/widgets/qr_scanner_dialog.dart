import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerDialog extends StatelessWidget {
  const QRScannerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return AlertDialog(
      backgroundColor: Colors.black,
      title: const Text('SCAN QR CODE', style: TextStyle(color: Colors.yellow)),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: isMobile
            ? MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      Navigator.pop(context, barcode.rawValue);
                      break;
                    }
                  }
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Scanner not available on Desktop.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Manual Entry (for testing)',
                      labelStyle: TextStyle(color: Colors.yellow),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                    ),
                    onSubmitted: (val) => Navigator.pop(context, val),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: Colors.yellow)),
        ),
      ],
    );
  }
}
