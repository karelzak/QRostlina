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
  int? _meter;
  int? _subRow;
  Bed? _currentBed;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.plant?.id ?? 'P-');
    _speciesIdController = TextEditingController(text: widget.plant?.speciesId ?? widget.initialSpeciesId ?? 'S-');
    _locationIdController = TextEditingController(text: widget.plant?.locationId ?? '');
    _status = widget.plant?.status ?? PlantStatus.inGround;
    _gridLine = widget.plant?.gridLine;
    _gridRow = widget.plant?.gridRow;
    
    _updateBedInfo();

    // Listen to location changes
    _locationIdController.addListener(() {
      _updateBedInfo();
    });
  }

  void _updateBedInfo() async {
    final locId = _locationIdController.text.trim().toUpperCase();
    if (locId.startsWith('B-')) {
      final bed = await MockDatabaseService.getBedById(locId);
      if (bed != null && mounted) {
        setState(() {
          _currentBed = bed;
          if (_gridRow != null) {
            _meter = ((_gridRow! - 1) / bed.rowsPerMeter).floor() + 1;
            _subRow = ((_gridRow! - 1) % bed.rowsPerMeter) + 1;
          }
        });
      }
    } else {
      setState(() {
        _currentBed = null;
        _gridLine = null;
        _gridRow = null;
        _meter = null;
        _subRow = null;
      });
    }
  }

  void _recalculateGridRow() {
    if (_currentBed != null && _meter != null) {
      if (_currentBed!.layout == BedLayout.grid && _subRow != null) {
        _gridRow = (_meter! - 1) * _currentBed!.rowsPerMeter + _subRow!;
      } else if (_currentBed!.layout == BedLayout.linear) {
        _gridRow = _meter;
      }
    }
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
      _recalculateGridRow();
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
              ),
              if (_currentBed != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_currentBed!.layout == BedLayout.grid) ...[
                      Expanded(
                        flex: 2,
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
                            DropdownMenuItem(value: 1, child: Text('Left')),
                            DropdownMenuItem(value: 2, child: Text('Right')),
                          ],
                          onChanged: (val) => setState(() => _gridLine = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _meter,
                        decoration: const InputDecoration(
                          labelText: 'Meter',
                          labelStyle: TextStyle(color: Colors.yellow),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                        ),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        items: List.generate(_currentBed!.length, (i) => i + 1)
                            .map((m) => DropdownMenuItem(value: m, child: Text('${m}m')))
                            .toList(),
                        onChanged: (val) => setState(() {
                          _meter = val;
                          _recalculateGridRow();
                        }),
                      ),
                    ),
                    if (_currentBed!.layout == BedLayout.grid) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          value: _subRow,
                          decoration: const InputDecoration(
                            labelText: 'Pos/m',
                            labelStyle: TextStyle(color: Colors.yellow),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                          ),
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          items: List.generate(_currentBed!.rowsPerMeter, (i) => i + 1)
                              .map((r) => DropdownMenuItem(value: r, child: Text('$r')))
                              .toList(),
                          onChanged: (val) => setState(() {
                            _subRow = val;
                            _recalculateGridRow();
                          }),
                        ),
                      ),
                    ],
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
