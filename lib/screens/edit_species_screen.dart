import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/species.dart';
import '../services/service_locator.dart';
import '../services/qr_scanner_service.dart';
import '../services/local_image_service.dart';
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

  String? _photoUrl;
  File? _localPhotoFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.species?.id ?? 'S-');
    _nameController = TextEditingController(text: widget.species?.name ?? '');
    _latinNameController = TextEditingController(text: widget.species?.latinName ?? '');
    _colorController = TextEditingController(text: widget.species?.color ?? '');
    _descriptionController = TextEditingController(text: widget.species?.description ?? '');
    _photoUrl = widget.species?.photoUrl;
    _loadLocalPhoto();
  }

  Future<void> _loadLocalPhoto() async {
    if (_photoUrl != null && !LocalImageService.isRemoteUrl(_photoUrl!)) {
      final file = await LocalImageService.getLocalFile(_photoUrl!);
      if (mounted) {
        setState(() {
          _localPhotoFile = file;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null && mounted) {
        setState(() {
          _localPhotoFile = File(pickedFile.path);
          // Clear _photoUrl because we have a new unsaved local file
          _photoUrl = null; 
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removePhoto() {
    setState(() {
      _localPhotoFile = null;
      _photoUrl = null;
    });
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
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      final id = _idController.text.trim().toUpperCase();
      
      // Check uniqueness for new entries
      if (widget.species == null) {
        final isUnique = await locator.db.isIdUnique(id);
        if (!isUnique) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.idExists(id))),
            );
          }
          return;
        }
      }

      String? finalPhotoUrl = _photoUrl;
      
      // If we have a new local photo file that hasn't been saved to app storage yet
      if (_localPhotoFile != null && _photoUrl == null) {
         final savedPath = await LocalImageService.saveImageLocally(_localPhotoFile!, id);
         if (savedPath != null) {
           finalPhotoUrl = savedPath;
         }
      }

      final species = Species(
        id: id,
        name: _nameController.text.trim(),
        latinName: _latinNameController.text.trim().isEmpty ? null : _latinNameController.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        photoUrl: finalPhotoUrl,
      );

      await locator.db.addSpecies(species);
      
      if (mounted) {
        // A tiny delay can help if the framework is locked during a transition/build
        Future.delayed(Duration.zero, () {
          if (mounted) {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop(true);
            }
          }
        });
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
              IdInputField(
                controller: _idController,
                label: 'Species ID (S-XXX)',
                type: ScannedType.species,
                enabled: !isEditing,
                validator: (val) {
                  if (val == null || val.trim().length <= 2 || !val.trim().toUpperCase().startsWith('S-')) {
                    return 'Required (e.g. S-001)';
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
                maxLines: 6,
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.yellow, thickness: 1),
              const SizedBox(height: 16),
              Text(l10n.photo.toUpperCase(), 
                style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildPhotoPicker(l10n),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 80),
                ),
                child: Text(l10n.save.toUpperCase()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(AppLocalizations l10n) {
    return Column(
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1, // Keep it square
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border.all(color: Colors.yellow),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _localPhotoFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.file(_localPhotoFile!, fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported, size: 64, color: Colors.white24),
                      ),
              ),
            ),
            if (_localPhotoFile != null)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: _removePhoto,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text(l10n.camera),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.gallery),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
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
