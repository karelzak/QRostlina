import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/service_locator.dart';
import '../services/qr_scanner_service.dart';
import '../widgets/id_input_field.dart';

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
  int _length = 10;
  int _rowsPerMeter = 2;
  BedLayout _layout = BedLayout.grid;

  @override
  void initState() {
    super.initState();
    final loc = widget.location;
    _idController = TextEditingController(text: loc?.id ?? (widget.isBed ? 'B-' : 'C-'));
    _nameController = TextEditingController(text: loc?.name ?? '');
    
    String extra = '';
    if (loc is Bed) {
      extra = loc.row ?? '';
      _length = loc.length;
      _rowsPerMeter = loc.rowsPerMeter;
      _layout = loc.layout;
    } else if (loc is Crate) {
      extra = loc.type;
    }
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
        final isUnique = await locator.db.isIdUnique(id);
        if (!isUnique) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ID $id already exists!')),
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
          length: _length,
          rowsPerMeter: _layout == BedLayout.grid ? _rowsPerMeter : 1,
          layout: _layout,
          speciesMap: widget.location is Bed ? (widget.location as Bed).speciesMap : null,
        );
      } else {
        loc = Crate(
          id: id,
          name: _nameController.text.trim(),
          type: _extraController.text.trim(),
          speciesIds: widget.location is Crate ? (widget.location as Crate).speciesIds : null,
        );
      }

      await locator.db.saveLocation(loc);
      if (mounted) Navigator.pop(context, loc.id);
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
              IdInputField(
                controller: _idController,
                label: 'ID (${widget.isBed ? "B-" : "C-"})',
                type: widget.isBed ? ScannedType.bed : ScannedType.crate,
                enabled: !isEditing,
                validator: (val) {
                  final prefix = widget.isBed ? 'B-' : 'C-';
                  if (val == null || val.trim().length <= 2 || !val.trim().toUpperCase().startsWith(prefix)) {
                    return 'Required (e.g. $prefix-001)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _extraController,
                label: widget.isBed ? 'Label (e.g. A)' : 'Crate Type (e.g. Plastic)',
              ),
              if (widget.isBed) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _length,
                  decoration: const InputDecoration(
                    labelText: 'Bed Length',
                    labelStyle: TextStyle(color: Colors.yellow),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                  ),
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10 Meters')),
                    DropdownMenuItem(value: 20, child: Text('20 Meters')),
                  ],
                  onChanged: (val) => setState(() => _length = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BedLayout>(
                  value: _layout,
                  decoration: const InputDecoration(
                    labelText: 'Layout Type',
                    labelStyle: TextStyle(color: Colors.yellow),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                  ),
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  items: const [
                    DropdownMenuItem(value: BedLayout.grid, child: Text('Grid (2 Lines)')),
                    DropdownMenuItem(value: BedLayout.linear, child: Text('Linear (Meters only)')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _layout = val!;
                      if (_layout == BedLayout.linear) {
                        _rowsPerMeter = 1;
                      } else if (_rowsPerMeter == 1) {
                        _rowsPerMeter = 2; // Default for grid
                      }
                    });
                  },
                ),
                if (_layout == BedLayout.grid) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _rowsPerMeter,
                    decoration: const InputDecoration(
                      labelText: 'Fragmentation (Density)',
                      labelStyle: TextStyle(color: Colors.yellow),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                    ),
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('2x2 (4 per meter)')),
                      DropdownMenuItem(value: 3, child: Text('2x3 (6 per meter)')),
                    ],
                    onChanged: (val) => setState(() => _rowsPerMeter = val!),
                  ),
                ],
              ],
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
