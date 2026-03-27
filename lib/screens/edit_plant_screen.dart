import 'package:flutter/material.dart';
import '../models/plant_unit.dart';
import '../models/location.dart';
import '../services/mock_database_service.dart';
import '../services/qr_scanner_service.dart';
import '../widgets/id_input_field.dart';
import '../widgets/search_dialog.dart';
import 'edit_species_screen.dart';
import 'edit_location_screen.dart';

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
  int? _gridLine;
  int? _gridRow;
  int? _meter;
  int? _subRow;
  Bed? _currentBed;

  @override
  void initState() {
    super.initState();
    // Use the provided plant ID, or if it's 'P-' (new from grid), keep it editable
    String initialId = widget.plant?.id ?? 'P-';
    
    _idController = TextEditingController(text: initialId);
    _speciesIdController = TextEditingController(text: widget.plant?.speciesId ?? widget.initialSpeciesId ?? 'S-');
    _locationIdController = TextEditingController(text: widget.plant?.locationId ?? '');
    _gridLine = widget.plant?.gridLine;
    _gridRow = widget.plant?.gridRow;
    
    _updateBedInfo();
  }

  void _checkPlantExists() async {
    final id = _idController.text.trim().toUpperCase();
    if (id.length <= 2 || !id.startsWith('P-')) return;

    final existingPlant = await MockDatabaseService.getPlantById(id);
    if (existingPlant != null && mounted) {
      setState(() {
        // We found an existing plant! 
        // We want to "MOVE" it, so we keep the NEW location but take its SPECIES
        _speciesIdController.text = existingPlant.speciesId;
        
        // If we are in a context where we ALREADY have a location (e.g. from grid), 
        // we DON'T overwrite _locationIdController, _gridLine, _gridRow.
        // But if we are just "Adding" from main menu, we might want to see where it was.
        if (_locationIdController.text.isEmpty || _locationIdController.text == 'P-') {
           _locationIdController.text = existingPlant.locationId ?? '';
           _gridLine = existingPlant.gridLine;
           _gridRow = existingPlant.gridRow;
           _updateBedInfo();
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Existing plant $id found. Moving to this location.'),
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _updateBedInfo() async {
    final locId = _locationIdController.text.trim().toUpperCase();
    if (locId.startsWith('B-')) {
      final bed = await MockDatabaseService.getBedById(locId);
      if (bed != null && mounted) {
        setState(() {
          _currentBed = bed;
          if (_gridRow != null) {
            _meter = ((_gridRow! - 1) / bed.rowsPerMeterEffective).floor() + 1;
            _subRow = ((_gridRow! - 1) % bed.rowsPerMeterEffective) + 1;
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _currentBed = null;
        });
      }
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
      final speciesId = _speciesIdController.text.trim().toUpperCase();
      final locationId = _locationIdController.text.trim().toUpperCase();

      // 1. Check Plant ID uniqueness ONLY if it's a NEW plant creation and NOT a "Move" operation.
      // We allow existing IDs now to support moving plants from one location to another.
      
      // 2. Validate Species Relation
      final sExists = await MockDatabaseService.speciesExists(speciesId);
      if (!sExists) {
        _showError('Species $speciesId does not exist!');
        return;
      }

      // 3. Validate Location Relation (if provided)
      if (locationId.isNotEmpty && locationId != 'NONE') {
        final lExists = await MockDatabaseService.locationExists(locationId);
        if (!lExists) {
          _showError('Location $locationId does not exist!');
          return;
        }
      }

      final plant = PlantUnit(
        id: id,
        speciesId: speciesId,
        locationId: locationId.isEmpty ? null : locationId,
        gridLine: _gridLine,
        gridRow: _gridRow,
      );

      await MockDatabaseService.savePlant(plant);
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _addSpecies() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (context) => const EditSpeciesScreen()),
    );
    if (result is String && mounted) {
      setState(() {
        _speciesIdController.text = result;
      });
    }
  }

  void _searchSpecies() async {
    final allSpecies = await MockDatabaseService.getAllSpecies();
    final items = allSpecies.map((s) => SearchItem(
      id: s.id,
      name: s.name,
      subtitle: s.latinName,
    )).toList();

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => SearchDialog(title: 'SEARCH SPECIES', items: items),
    );

    if (result != null && mounted) {
      setState(() {
        _speciesIdController.text = result;
      });
    }
  }

  void _addLocation() async {
    final isBed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add New Location', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.grid_view, color: Colors.yellow),
              title: const Text('New Bed (B-)', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.yellow),
              title: const Text('New Crate (C-)', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (isBed != null && mounted) {
      final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(builder: (context) => EditLocationScreen(isBed: isBed)),
      );
      if (result is String && mounted) {
        setState(() {
          _locationIdController.text = result;
        });
        _updateBedInfo();
      }
    }
  }

  void _searchLocation() async {
    final beds = await MockDatabaseService.getAllBeds();
    final crates = await MockDatabaseService.getAllCrates();
    
    final items = [
      ...beds.map((b) => SearchItem(
        id: b.id,
        name: b.name,
        subtitle: 'Bed (Row: ${b.row ?? "-"})',
      )),
      ...crates.map((c) => SearchItem(
        id: c.id,
        name: c.name,
        subtitle: 'Crate (Type: ${c.type})',
      )),
    ];

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => SearchDialog(title: 'SEARCH LOCATION', items: items),
    );

    if (result != null && mounted) {
      setState(() {
        _locationIdController.text = result;
      });
      _updateBedInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRealEdit = widget.plant != null && widget.plant!.id != 'P-';

    return Scaffold(
      appBar: AppBar(
        title: Text(isRealEdit ? 'EDIT PLANT' : 'ADD/MOVE PLANT'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              IdInputField(
                controller: _idController,
                label: 'Plant ID (P-XXX)',
                type: ScannedType.plant,
                enabled: !isRealEdit,
                onChanged: _checkPlantExists,
                validator: (val) {
                  if (val == null || val.trim().length <= 2 || !val.trim().toUpperCase().startsWith('P-')) {
                    return 'Required (e.g. P-001)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              IdInputField(
                controller: _speciesIdController,
                label: 'Species ID (S-XXX)',
                type: ScannedType.species,
                onAdd: _addSpecies,
                onSearch: _searchSpecies,
                validator: (val) {
                  if (val == null || val.trim().length <= 2 || !val.trim().toUpperCase().startsWith('S-')) {
                    return 'Required (e.g. S-001)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              IdInputField(
                controller: _locationIdController,
                label: 'Location ID (B- or C-)',
                type: ScannedType.unknown,
                onAdd: _addLocation,
                onSearch: _searchLocation,
                onChanged: _updateBedInfo,
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.trim().length <= 2) {
                     return 'Invalid ID';
                  }
                  return null;
                },
              ),
              if (_currentBed != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
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
}
