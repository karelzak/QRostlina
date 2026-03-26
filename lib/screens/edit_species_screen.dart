import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/species.dart';
import '../services/mock_database_service.dart';

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
  late TextEditingController _heightController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.species?.id ?? 'S-');
    _nameController = TextEditingController(text: widget.species?.name ?? '');
    _latinNameController = TextEditingController(text: widget.species?.latinName ?? '');
    _colorController = TextEditingController(text: widget.species?.color ?? '');
    _heightController = TextEditingController(text: widget.species?.height ?? '');
    _descriptionController = TextEditingController(text: widget.species?.description ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _latinNameController.dispose();
    _colorController.dispose();
    _heightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final species = Species(
        id: _idController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        latinName: _latinNameController.text.trim().isEmpty ? null : _latinNameController.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        height: _heightController.text.trim().isEmpty ? null : _heightController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );

      // In Mock mode, we just add or update in memory
      await MockDatabaseService.addSpecies(species);
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to signal refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.species != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'EDIT SPECIES' : l10n.addNewSpecies),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _idController,
                label: 'ID (e.g. S-123)',
                enabled: !isEditing, // ID is immutable after creation
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
              _buildTextField(controller: _heightController, label: 'Height (cm)'),
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
