import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../services/qr_scanner_service.dart';
import '../widgets/qr_scanner_dialog.dart';

class IdInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ScannedType type;
  final bool enabled;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;
  final VoidCallback? onAdd;
  final VoidCallback? onSearch;

  const IdInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.type,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onAdd,
    this.onSearch,
  });

  Future<void> _scan(BuildContext context) async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const QRScannerDialog(),
    );
    if (code != null) {
      final result = QRScannerService.parse(code);
      if (result.type == type || type == ScannedType.unknown) {
        controller.text = result.id;
        if (onChanged != null) onChanged!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid label type. Expected ${type.name}')),
        );
      }
    }
  }

  Future<void> _generate() async {
    final nextId = await locator.db.generateNextId(type);
    controller.text = nextId;
    if (onChanged != null) onChanged!();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            validator: validator,
            onChanged: (_) => onChanged?.call(),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.yellow),
              disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow, width: 2)),
              errorStyle: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
        if (enabled) ...[
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.yellow),
            onPressed: () => _scan(context),
            tooltip: 'Scan QR',
          ),
          if (onSearch != null)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.yellow),
              onPressed: onSearch,
              tooltip: 'Search',
            ),
          if (onAdd != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.yellow),
              onPressed: onAdd,
              tooltip: 'Create New',
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_fix_high, color: Colors.yellow),
              onPressed: _generate,
              tooltip: 'Auto ID',
            ),
        ],
      ],
    );
  }
}
