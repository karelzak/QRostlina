import 'package:flutter/material.dart';
import '../models/plant_unit.dart';
import '../services/mock_database_service.dart';
import '../services/qr_scanner_service.dart';

class EditPlantScreen extends StatefulWidget {
  final PlantUnit? plant;
  final String? initialSpeciesId;

  const EditPlantScreen({super.key, this.plant, this.initialSpeciesId});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _speciesIdController;
  late TextEditingController _locationIdController;
  late PlantStatus _status;
  int? _gridLine;
  int? _gridRow;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.plant?.id ?? 'P-');
    _speciesIdController = TextEditingController(text: widget.plant?.speciesId ?? widget.initialSpeciesId ?? 'S-');
    _locationIdController = TextEditingController(text: widget.plant?.locationId ?? '');
    _status = widget.plant?.status ?? PlantStatus.inGround;
    _gridLine = widget.plant?.gridLine;
    _gridRow = widget.plant?.gridRow;

    // Listen to location changes to show/hide grid fields
    _locationIdController.addListener(() {
      if (!_locationIdController.text.startsWith('B-')) {
        setState(() {
          _gridLine = null;
          _gridRow = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _speciesIdController.dispose();
    _locationIdController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final id = _idController.text.trim().toUpperCase();

      if (widget.plant == null) {
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

      final plant = PlantUnit(
        id: id,
        speciesId: _speciesIdController.text.trim().toUpperCase(),
        status: _status,
        locationId: _locationIdController.text.trim().isEmpty ? null : _locationIdController.text.trim().toUpperCase(),
        gridLine: _gridLine,
        gridRow: _gridRow,
      );

      await MockDatabaseService.savePlant(plant);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plant != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'EDIT PLANT' : 'ADD NEW PLANT'),
      ),
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
                      label: 'Plant ID (P-XXX)',
                      enabled: !isEditing,
                      validator: (val) => (val == null || !val.startsWith('P-')) ? 'Must start with P-' : null,
                    ),
                  ),
                  if (!isEditing)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.auto_fix_high, color: Colors.yellow, size: 32),
                        onPressed: () async {
                          final nextId = await MockDatabaseService.generateNextId(ScannedType.plant);
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
                controller: _speciesIdController,
                label: 'Species ID (S-XXX)',
                validator: (val) => (val == null || !val.startsWith('S-')) ? 'Must start with S-' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationIdController,
                label: 'Location ID (B- or C-)',
                hint: 'e.g. B-01 or C-05',
                onChanged: (val) => setState(() {}),
              ),
              if (_locationIdController.text.startsWith('B-')) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _gridLine,
                        decoration: const InputDecoration(
                          labelText: 'Line',
                          labelStyle: TextStyle(color: Colors.yellow),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                        ),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Left (1)')),
                          DropdownMenuItem(value: 2, child: Text('Right (2)')),
                        ],
                        onChanged: (val) => setState(() => _gridLine = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _gridRow?.toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: 'Row # (1-60)',
                          labelStyle: TextStyle(color: Colors.yellow),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                        ),
                        onChanged: (val) => _gridRow = int.tryParse(val),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<PlantStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(color: Colors.yellow),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                ),
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                items: PlantStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                child: const Text('SAVE PLANT'),
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
    String? hint,
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
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.yellow),
        disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow, width: 2)),
      ),
    );
  }
}
