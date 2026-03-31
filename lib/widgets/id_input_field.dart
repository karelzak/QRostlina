import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/qr_scanner_service.dart';
import '../services/service_locator.dart';
import 'qr_scanner_dialog.dart';

class IdInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ScannedType type;
  final bool enabled;
  final String? Function(String?)? validator;

  const IdInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.type,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.yellow),
              disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow, width: 2)),
              errorStyle: const TextStyle(color: Colors.redAccent),
            ),
            validator: validator,
          ),
        ),
        if (enabled) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.auto_fix_high, color: Colors.yellow, size: 30),
            onPressed: () async {
              final nextId = await locator.db.generateNextId(type);
              controller.text = nextId;
            },
            tooltip: 'Generate Next ID',
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.yellow, size: 30),
            onPressed: () async {
              final result = await showDialog<QRResult>(
                context: context,
                builder: (context) => const QRScannerDialog(),
              );

              if (result != null) {
                if (result.type == type) {
                  controller.text = result.id;
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.invalidLabelType(type.name))),
                    );
                  }
                }
              }
            },
            tooltip: 'Scan QR Code',
          ),
        ],
      ],
    );
  }
}
