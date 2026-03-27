import 'package:flutter/material.dart';
import '../services/mock_database_service.dart';
import '../services/qr_scanner_service.dart';
import '../widgets/id_input_field.dart';

class EditSpeciesScreen extends StatefulWidget {
  final Species? species; // If null, we're adding new; else editing

  const EditSpeciesScreen({super.key, this.species});

  @override
  State<EditSpeciesScreen> createState() => _EditSpeciesScreenState();
}

class _EditSpeciesScreenState extends State<EditSpeciesScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _latinNameController;
  late TextEditingController _colorController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.species?.id ?? 'S-');
    _nameController = TextEditingController(text: widget.species?.name ?? '');
    _latinNameController = TextEditingController(text: widget.species?.latinName ?? '');
    _colorController = TextEditingController(text: widget.species?.color ?? '');
    _descriptionController = TextEditingController(text: widget.species?.description ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _latinNameController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final id = _idController.text.trim().toUpperCase();
      
      // Check uniqueness for new entries
      if (widget.species == null) {
        final isUnique = await MockDatabaseService.isIdUnique(id);
        if (!isUnique) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ID $id already exists!')),
            );
          }
          return;
        }
      }

      final species = Species(
        id: id,
        name: _nameController.text.trim(),
        latinName: _latinNameController.text.trim().isEmpty ? null : _latinNameController.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );

      await MockDatabaseService.addSpecies(species);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.species != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'EDIT SPECIES' : 'ADD NEW SPECIES'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              IdInputField(
                controller: _idController,
                label: 'Species ID (S-XXX)',
                type: ScannedType.species,
                enabled: !isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.startsWith('S-')) {
                    return 'Must start with S-';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Variety Name',
                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _latinNameController, label: 'Latin Name'),
              const SizedBox(height: 16),
              _buildTextField(controller: _colorController, label: 'Color'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: const Text('SAVE SPECIES'),
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.yellow),
        disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow, width: 2)),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
