import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/species.dart';
import '../models/plant_unit.dart';
import '../models/location.dart';
import 'qr_scanner_service.dart';

class MockDatabaseService {
  static bool _initialized = false;

  // Static mock data for development
  static final List<Species> _mockSpecies = [
    Species(
      id: 'S-001',
      name: 'Cornel Bronze',
      latinName: 'Dahlia pinnata',
      color: 'Bronze/Orange',
      description: 'Ball dahlia with strong stems.',
    ),
    Species(
      id: 'S-002',
      name: 'Cafe au Lait',
      latinName: 'Dahlia pinnata',
      color: 'Creamy Pink',
      description: 'Large decorative dinner plate dahlia.',
    ),
  ];

  static final List<PlantUnit> _mockPlants = [
    PlantUnit(id: 'P-001', speciesId: 'S-001', locationId: 'B-01', gridLine: 1, gridRow: 1),
    PlantUnit(id: 'P-002', speciesId: 'S-001', locationId: 'C-01'),
    PlantUnit(id: 'P-003', speciesId: 'S-002', locationId: 'B-01', gridLine: 2, gridRow: 5),
    PlantUnit(id: 'P-004', speciesId: 'S-001', locationId: 'B-03', gridRow: 5),
  ];

  static final List<Bed> _mockBeds = [
    Bed(id: 'B-01', name: 'West Garden - Bed A', row: 'A', length: 20, rowsPerMeter: 2), // 20m, 2x2 = 80 cells
    Bed(id: 'B-02', name: 'West Garden - Bed B', row: 'B', length: 10, rowsPerMeter: 3), // 10m, 2x3 = 60 cells
    Bed(id: 'B-03', name: 'North Border', row: 'NB', length: 10, layout: BedLayout.linear, rowsPerMeter: 1), // 10m Linear
  ];

  static final List<Crate> _mockCrates = [
    Crate(id: 'C-01', name: 'Greenhouse Crate #1', type: 'Plastic'),
    Crate(id: 'C-02', name: 'Storage Crate #2', type: 'Wooden'),
  ];

  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/qrostlina_data.json');
  }

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        if (data.containsKey('species')) {
          _mockSpecies.clear();
          for (var s in data['species']) {
            _mockSpecies.add(Species.fromMap(s));
          }
        }
        if (data.containsKey('plants')) {
          _mockPlants.clear();
          for (var p in data['plants']) {
            _mockPlants.add(PlantUnit.fromMap(p));
          }
        }
        if (data.containsKey('beds')) {
          _mockBeds.clear();
          for (var b in data['beds']) {
            _mockBeds.add(Bed.fromMap(b));
          }
        }
        if (data.containsKey('crates')) {
          _mockCrates.clear();
          for (var c in data['crates']) {
            _mockCrates.add(Crate.fromMap(c));
          }
        }
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  static Future<void> _saveData() async {
    try {
      final file = await _getFile();
      final Map<String, dynamic> data = {
        'species': _mockSpecies.map((s) => s.toMap()).toList(),
        'plants': _mockPlants.map((p) => p.toMap()).toList(),
        'beds': _mockBeds.map((b) => b.toMap()).toList(),
        'crates': _mockCrates.map((c) => c.toMap()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  static Future<bool> isIdUnique(String id) async {
    await _ensureInitialized();
    final type = QRScannerService.parse(id).type;
    switch (type) {
      case ScannedType.species:
        return !_mockSpecies.any((s) => s.id == id);
      case ScannedType.plant:
        return !_mockPlants.any((p) => p.id == id);
      case ScannedType.bed:
        return !_mockBeds.any((b) => b.id == id);
      case ScannedType.crate:
        return !_mockCrates.any((c) => c.id == id);
      default:
        return true;
    }
  }

  static Future<String> generateNextId(ScannedType type) async {
    await _ensureInitialized();
    String prefix;
    List<String> existingIds;

    switch (type) {
      case ScannedType.species:
        prefix = 'S-';
        existingIds = _mockSpecies.map((e) => e.id).toList();
        break;
      case ScannedType.plant:
        prefix = 'P-';
        existingIds = _mockPlants.map((e) => e.id).toList();
        break;
      case ScannedType.bed:
        prefix = 'B-';
        existingIds = _mockBeds.map((e) => e.id).toList();
        break;
      case ScannedType.crate:
        prefix = 'C-';
        existingIds = _mockCrates.map((e) => e.id).toList();
        break;
      default:
        throw Exception('Cannot generate ID for unknown type');
    }

    int maxId = 0;
    for (var id in existingIds) {
      final numericPart = id.substring(prefix.length);
      final val = int.tryParse(numericPart) ?? 0;
      if (val > maxId) maxId = val;
    }

    final nextVal = maxId + 1;
    return '$prefix${nextVal.toString().padLeft(3, '0')}';
  }

  static Future<List<Species>> getAllSpecies() async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockSpecies;
  }

  static Future<List<Bed>> getAllBeds() async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockBeds;
  }

  static Future<List<Crate>> getAllCrates() async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockCrates;
  }

  static Future<Species?> getSpeciesById(String id) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockSpecies.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<PlantUnit?> getPlantById(String id) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockPlants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<Bed?> getBedById(String id) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockBeds.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<Crate?> getCrateById(String id) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockCrates.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> speciesExists(String id) async {
    await _ensureInitialized();
    return _mockSpecies.any((s) => s.id == id);
  }

  static Future<bool> locationExists(String id) async {
    await _ensureInitialized();
    if (id.startsWith('B-')) return _mockBeds.any((b) => b.id == id);
    if (id.startsWith('C-')) return _mockCrates.any((c) => c.id == id);
    return false;
  }

  static Future<List<PlantUnit>> getPlantsByLocation(String locationId) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockPlants.where((p) => p.locationId == locationId).toList();
  }

  static Future<List<PlantUnit>> getPlantsBySpecies(String speciesId) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockPlants.where((p) => p.speciesId == speciesId).toList();
  }

  static Future<void> addSpecies(Species species) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockSpecies.indexWhere((s) => s.id == species.id);
    if (index >= 0) {
      _mockSpecies[index] = species;
    } else {
      _mockSpecies.add(species);
    }
    await _saveData();
  }

  static Future<List<PlantUnit>> getAllPlants() async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockPlants;
  }

  static Future<void> deleteSpecies(String id) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    _mockSpecies.removeWhere((s) => s.id == id);
    _mockPlants.removeWhere((p) => p.speciesId == id);
    await _saveData();
  }

  static Future<void> deletePlant(String id) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    _mockPlants.removeWhere((p) => p.id == id);
    await _saveData();
  }

  static Future<void> deleteLocation(String id) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    if (id.startsWith('B-')) {
      _mockBeds.removeWhere((b) => b.id == id);
    } else if (id.startsWith('C-')) {
      _mockCrates.removeWhere((c) => c.id == id);
    }
    // Update plants at this location to have no location
    for (var i = 0; i < _mockPlants.length; i++) {
      if (_mockPlants[i].locationId == id) {
        _mockPlants[i] = PlantUnit(
          id: _mockPlants[i].id,
          speciesId: _mockPlants[i].speciesId,
          locationId: null,
        );
      }
    }
    await _saveData();
  }

  static Future<void> savePlant(PlantUnit plant) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockPlants.indexWhere((p) => p.id == plant.id);
    if (index >= 0) {
      _mockPlants[index] = plant;
    } else {
      _mockPlants.add(plant);
    }
    await _saveData();
  }

  static Future<void> saveLocation(Location location) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    if (location is Bed) {
      final index = _mockBeds.indexWhere((b) => b.id == location.id);
      if (index >= 0) _mockBeds[index] = location;
      else _mockBeds.add(location);
    } else if (location is Crate) {
      final index = _mockCrates.indexWhere((c) => c.id == location.id);
      if (index >= 0) _mockCrates[index] = location;
      else _mockCrates.add(location);
    }
    await _saveData();
  }
}
