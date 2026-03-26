import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/mock_database_service.dart';
import '../services/qr_scanner_service.dart';

class EditLocationScreen extends StatefulWidget {
  final Location? location;
  final bool isBed;

  const EditLocationScreen({super.key, this.location, this.isBed = true});

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _extraController; // Row for Bed, Type for Crate

  @override
  void initState() {
    super.initState();
    final loc = widget.location;
    _idController = TextEditingController(text: loc?.id ?? (widget.isBed ? 'B-' : 'C-'));
    _nameController = TextEditingController(text: loc?.name ?? '');
    
    String extra = '';
    if (loc is Bed) extra = loc.row ?? '';
    else if (loc is Crate) extra = loc.type;
    _extraController = TextEditingController(text: extra);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final id = _idController.text.trim().toUpperCase();

      if (widget.location == null) {
        final isUnique = await MockDatabaseService.isIdUnique(id);
        if (!isUnique) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ID already exists!')),
            );
          }
          return;
        }
      }

      Location loc;
      if (widget.isBed) {
        loc = Bed(
          id: id,
          name: _nameController.text.trim(),
          row: _extraController.text.trim(),
        );
      } else {
        loc = Crate(
          id: id,
          name: _nameController.text.trim(),
          type: _extraController.text.trim(),
        );
      }

      await MockDatabaseService.saveLocation(loc);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.location != null;
    final typeLabel = widget.isBed ? 'BED' : 'CRATE';

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'EDIT $typeLabel' : 'ADD NEW $typeLabel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _idController,
                      label: 'ID (${widget.isBed ? "B-" : "C-"})',
                      enabled: !isEditing,
                      validator: (val) {
                        final prefix = widget.isBed ? 'B-' : 'C-';
                        if (val == null || !val.startsWith(prefix)) return 'Must start with $prefix';
                        return null;
                      },
                    ),
                  ),
                  if (!isEditing)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.auto_fix_high, color: Colors.yellow, size: 32),
                        onPressed: () async {
                          final type = widget.isBed ? ScannedType.bed : ScannedType.crate;
                          final nextId = await MockDatabaseService.generateNextId(type);
                          setState(() {
                            _idController.text = nextId;
                          });
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Name / Label',
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _extraController,
                label: widget.isBed ? 'Row / Section' : 'Crate Type (e.g. Plastic)',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                child: Text('SAVE $typeLabel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.yellow),
        disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow, width: 2)),
      ),
    );
  }
}
