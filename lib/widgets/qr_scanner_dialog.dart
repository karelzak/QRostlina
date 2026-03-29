import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../l10n/app_localizations.dart';
import '../services/qr_scanner_service.dart';

class QRScannerDialog extends StatefulWidget {
  const QRScannerDialog({super.key});

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: Colors.black,
      title: Text(l10n.scanQrCode, style: const TextStyle(color: Colors.yellow)),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: (Platform.isAndroid || Platform.isIOS)
            ? MobileScanner(
                controller: controller,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final code = barcodes.first.rawValue;
                    if (code != null) {
                      final result = QRScannerService.parse(code);
                      Navigator.pop(context, result);
                    }
                  }
                },
              )
            : Center(
                child: Text(l10n.scannerNotAvailable, style: const TextStyle(color: Colors.white70)),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.yellow)),
        ),
      ],
    );
  }
}
