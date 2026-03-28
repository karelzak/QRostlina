import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/species.dart';
import '../models/location.dart';
import 'qr_scanner_service.dart';

class MockDatabaseService {
  static bool _initialized = false;

  static final List<Species> _mockSpecies = [];
  static final List<Bed> _mockBeds = [];
  static final List<Crate> _mockCrates = [];

  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/qrostlina_data.json');
  }

  static Future<void> exportData(String path) async {
    await _ensureInitialized();
    final Map<String, dynamic> data = {
      'species': _mockSpecies.map((s) => s.toMap()).toList(),
      'beds': _mockBeds.map((b) => b.toMap()).toList(),
      'crates': _mockCrates.map((c) => c.toMap()).toList(),
    };
    final file = File(path);
    await file.writeAsString(jsonEncode(data));
  }

  static Future<void> importData(String path) async {
    final file = File(path);
    if (!await file.exists()) throw Exception('Import file not found');
    
    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    _mockSpecies.clear();
    if (data.containsKey('species')) {
      for (var s in data['species']) {
        _mockSpecies.add(Species.fromMap(s));
      }
    }
    _mockBeds.clear();
    if (data.containsKey('beds')) {
      for (var b in data['beds']) {
        _mockBeds.add(Bed.fromMap(b));
      }
    }
    _mockCrates.clear();
    if (data.containsKey('crates')) {
      for (var c in data['crates']) {
        _mockCrates.add(Crate.fromMap(c));
      }
    }
    
    await _saveData();
    _initialized = true;
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
      debugPrint('Error loading data: $e');
    }
  }

  static Future<void> _saveData() async {
    try {
      final file = await _getFile();
      final Map<String, dynamic> data = {
        'species': _mockSpecies.map((s) => s.toMap()).toList(),
        'beds': _mockBeds.map((b) => b.toMap()).toList(),
        'crates': _mockCrates.map((c) => c.toMap()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  static Future<bool> isIdUnique(String id) async {
    await _ensureInitialized();
    final type = QRScannerService.parse(id).type;
    switch (type) {
      case ScannedType.species:
        return !_mockSpecies.any((s) => s.id == id);
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
    return _mockSpecies;
  }

  static Future<List<Bed>> getAllBeds() async {
    await _ensureInitialized();
    return _mockBeds;
  }

  static Future<List<Crate>> getAllCrates() async {
    await _ensureInitialized();
    return _mockCrates;
  }

  static Future<Species?> getSpeciesById(String id) async {
    await _ensureInitialized();
    try {
      return _mockSpecies.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<Bed?> getBedById(String id) async {
    await _ensureInitialized();
    try {
      return _mockBeds.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<Crate?> getCrateById(String id) async {
    await _ensureInitialized();
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
    if (id.startsWith('B-')) {
      return _mockBeds.any((b) => b.id == id);
    }
    if (id.startsWith('C-')) {
      return _mockCrates.any((c) => c.id == id);
    }
    return false;
  }

  static Future<void> addSpecies(Species species) async {
    await _ensureInitialized();
    final index = _mockSpecies.indexWhere((s) => s.id == species.id);
    if (index >= 0) {
      _mockSpecies[index] = species;
    } else {
      _mockSpecies.add(species);
    }
    await _saveData();
  }

  static Future<void> deleteSpecies(String id) async {
    await _ensureInitialized();
    _mockSpecies.removeWhere((s) => s.id == id);
    // Remove from all beds
    for (var bed in _mockBeds) {
      bed.speciesMap.removeWhere((key, value) => value == id);
    }
    // Remove from all crates
    for (var crate in _mockCrates) {
      crate.speciesIds.removeWhere((element) => element == id);
    }
    await _saveData();
  }

  static Future<void> deleteLocation(String id) async {
    await _ensureInitialized();
    if (id.startsWith('B-')) {
      _mockBeds.removeWhere((b) => b.id == id);
    } else if (id.startsWith('C-')) {
      _mockCrates.removeWhere((c) => c.id == id);
    }
    await _saveData();
  }

  static Future<void> saveLocation(Location location) async {
    await _ensureInitialized();
    if (location is Bed) {
      final index = _mockBeds.indexWhere((b) => b.id == location.id);
      if (index >= 0) {
        _mockBeds[index] = location;
      } else {
        _mockBeds.add(location);
      }
    } else if (location is Crate) {
      final index = _mockCrates.indexWhere((c) => c.id == location.id);
      if (index >= 0) {
        _mockCrates[index] = location;
      } else {
        _mockCrates.add(location);
      }
    }
    await _saveData();
  }

  static Future<List<String>> getLocationsForSpecies(String speciesId) async {
    await _ensureInitialized();
    List<String> locations = [];
    
    for (var bed in _mockBeds) {
      bed.speciesMap.forEach((key, sId) {
        if (sId == speciesId) {
          final parts = key.split('-');
          final line = int.tryParse(parts[0]);
          final row = int.tryParse(parts[1]);
          locations.add(bed.formatPosition(line, row));
        }
      });
    }

    for (var crate in _mockCrates) {
      if (crate.speciesIds.contains(speciesId)) {
        locations.add(crate.id);
      }
    }

    return locations;
  }

  static Future<void> setSpeciesAtBedCell(String bedId, int line, int row, String? speciesId) async {
    await _ensureInitialized();
    final bed = await getBedById(bedId);
    if (bed != null) {
      final key = "$line-$row";
      if (speciesId == null) {
        bed.speciesMap.remove(key);
      } else {
        bed.speciesMap[key] = speciesId;
      }
      await _saveData();
    }
  }

  static Future<void> addSpeciesToCrate(String crateId, String speciesId) async {
    await _ensureInitialized();
    final crate = await getCrateById(crateId);
    if (crate != null && !crate.speciesIds.contains(speciesId)) {
      crate.speciesIds.add(speciesId);
      await _saveData();
    }
  }

  static Future<void> removeSpeciesFromCrate(String crateId, String speciesId) async {
    await _ensureInitialized();
    final crate = await getCrateById(crateId);
    if (crate != null) {
      crate.speciesIds.remove(speciesId);
      await _saveData();
    }
  }

  static Future<void> clearLocation(String id) async {
    await _ensureInitialized();
    if (id.startsWith('B-')) {
      final bed = await getBedById(id);
      if (bed != null) {
        bed.speciesMap.clear();
        await _saveData();
      }
    } else if (id.startsWith('C-')) {
      final crate = await getCrateById(id);
      if (crate != null) {
        crate.speciesIds.clear();
        await _saveData();
      }
    }
  }
}
