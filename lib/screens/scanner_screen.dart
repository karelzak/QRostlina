import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../l10n/app_localizations.dart';
import '../services/qr_scanner_service.dart';
import '../widgets/species_selection_dialog.dart';
import 'detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _manualIdController = TextEditingController();
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandlingCode = false;

  @override
  void dispose() {
    _manualIdController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isHandlingCode) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() => _isHandlingCode = true);
        _handleCode(code);
        break; 
      }
    }
  }

  Future<void> _handleCode(String code) async {
    final result = QRScannerService.parse(code);
    final l10n = AppLocalizations.of(context)!;
    
    // Show a quick snackbar for feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.scanned}: ${result.id} (${result.type.name})'),
        duration: const Duration(seconds: 1),
      ),
    );

    // Navigation to specific cards based on type
    debugPrint('Detected ${result.type}: ${result.id}');
    if (result.type == ScannedType.species) {
      SpeciesSelectionDialog.addToHistory(result.id);
    }
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(id: result.id, type: result.type),
      ),
    );

    // Reset flag when coming back to the scanner
    if (mounted) {
      setState(() => _isHandlingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // mobile_scanner doesn't support Linux/Desktop yet, so we show a manual input for testing on Linux
    bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanQrCode)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: isMobile
                  ? MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: Text(
                          l10n.cameraOnlyMobile,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
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
                      labelText: l10n.manualIdEntry,
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
                    child: Text(l10n.submitId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
