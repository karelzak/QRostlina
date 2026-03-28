import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/species.dart';
import '../models/location.dart';
import 'database_service.dart';
import 'qr_scanner_service.dart';

class LocalStorageService implements DatabaseService {
  bool _initialized = false;
  Completer<void>? _initCompleter;
  static const _encoder = JsonEncoder.withIndent('  ');

  final List<Species> _species = [];
  final List<Bed> _beds = [];
  final List<Crate> _crates = [];

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/qrostlina_data.json');
  }

  @override
  Future<void> initialize() async {
    await _ensureInitialized();
  }

  @override
  Future<void> exportData(String path) async {
    await _ensureInitialized();
    final Map<String, dynamic> data = {
      'species': _species.map((s) => s.toMap()).toList(),
      'beds': _beds.map((b) => b.toMap()).toList(),
      'crates': _crates.map((c) => c.toMap()).toList(),
    };
    final file = File(path);
    await file.writeAsString(_encoder.convert(data));
  }

  @override
  Future<void> importData(String path) async {
    final file = File(path);
    if (!await file.exists()) throw Exception('Import file not found');
    
    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    _species.clear();
    if (data.containsKey('species')) {
      for (var s in data['species']) {
        _species.add(Species.fromMap(s));
      }
    }
    _beds.clear();
    if (data.containsKey('beds')) {
      for (var b in data['beds']) {
        _beds.add(Bed.fromMap(b));
      }
    }
    _crates.clear();
    if (data.containsKey('crates')) {
      for (var c in data['crates']) {
        _crates.add(Crate.fromMap(c));
      }
    }
    
    await _saveData();
    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        if (data.containsKey('species')) {
          _species.clear();
          for (var s in data['species']) {
            _species.add(Species.fromMap(s));
          }
        }
        if (data.containsKey('beds')) {
          _beds.clear();
          for (var b in data['beds']) {
            _beds.add(Bed.fromMap(b));
          }
        }
        if (data.containsKey('crates')) {
          _crates.clear();
          for (var c in data['crates']) {
            _crates.add(Crate.fromMap(c));
          }
        }
      }
      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      debugPrint('Error loading data: $e');
      _initCompleter!.complete();
      _initCompleter = null;
    }
  }

  Future<void> _saveData() async {
    try {
      final file = await _getFile();
      final Map<String, dynamic> data = {
        'species': _species.map((s) => s.toMap()).toList(),
        'beds': _beds.map((b) => b.toMap()).toList(),
        'crates': _crates.map((c) => c.toMap()).toList(),
      };
      await file.writeAsString(_encoder.convert(data));
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  @override
  Future<bool> isIdUnique(String id) async {
    await _ensureInitialized();
    final type = QRScannerService.parse(id).type;
    switch (type) {
      case ScannedType.species:
        return !_species.any((s) => s.id == id);
      case ScannedType.bed:
        return !_beds.any((b) => b.id == id);
      case ScannedType.crate:
        return !_crates.any((c) => c.id == id);
      default:
        return true;
    }
  }

  @override
  Future<String> generateNextId(ScannedType type) async {
    await _ensureInitialized();
    String prefix;
    List<String> existingIds;

    switch (type) {
      case ScannedType.species:
        prefix = 'S-';
        existingIds = _species.map((e) => e.id).toList();
        break;
      case ScannedType.bed:
        prefix = 'B-';
        existingIds = _beds.map((e) => e.id).toList();
        break;
      case ScannedType.crate:
        prefix = 'C-';
        existingIds = _crates.map((e) => e.id).toList();
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

  @override
  Future<List<Species>> getAllSpecies() async {
    await _ensureInitialized();
    return _species;
  }

  @override
  Future<List<Bed>> getAllBeds() async {
    await _ensureInitialized();
    return _beds;
  }

  @override
  Future<List<Crate>> getAllCrates() async {
    await _ensureInitialized();
    return _crates;
  }

  @override
  Future<Species?> getSpeciesById(String id) async {
    await _ensureInitialized();
    try {
      return _species.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Bed?> getBedById(String id) async {
    await _ensureInitialized();
    try {
      return _beds.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Crate?> getCrateById(String id) async {
    await _ensureInitialized();
    try {
      return _crates.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> speciesExists(String id) async {
    await _ensureInitialized();
    return _species.any((s) => s.id == id);
  }

  @override
  Future<bool> locationExists(String id) async {
    await _ensureInitialized();
    if (id.startsWith('B-')) {
      return _beds.any((b) => b.id == id);
    }
    if (id.startsWith('C-')) {
      return _crates.any((c) => c.id == id);
    }
    return false;
  }

  @override
  Future<void> addSpecies(Species species) async {
    await _ensureInitialized();
    final index = _species.indexWhere((s) => s.id == species.id);
    if (index >= 0) {
      _species[index] = species;
    } else {
      _species.add(species);
    }
    await _saveData();
  }

  @override
  Future<void> deleteSpecies(String id) async {
    await _ensureInitialized();
    _species.removeWhere((s) => s.id == id);
    // Remove from all beds
    for (var bed in _beds) {
      bed.speciesMap.removeWhere((key, value) => value == id);
    }
    // Remove from all crates
    for (var crate in _crates) {
      crate.speciesIds.removeWhere((element) => element == id);
    }
    await _saveData();
  }

  @override
  Future<void> deleteLocation(String id) async {
    await _ensureInitialized();
    if (id.startsWith('B-')) {
      _beds.removeWhere((b) => b.id == id);
    } else if (id.startsWith('C-')) {
      _crates.removeWhere((c) => c.id == id);
    }
    await _saveData();
  }

  @override
  Future<void> saveLocation(Location location) async {
    await _ensureInitialized();
    if (location is Bed) {
      final index = _beds.indexWhere((b) => b.id == location.id);
      if (index >= 0) {
        _beds[index] = location;
      } else {
        _beds.add(location);
      }
    } else if (location is Crate) {
      final index = _crates.indexWhere((c) => c.id == location.id);
      if (index >= 0) {
        _crates[index] = location;
      } else {
        _crates.add(location);
      }
    }
    await _saveData();
  }

  @override
  Future<List<String>> getLocationsForSpecies(String speciesId) async {
    await _ensureInitialized();
    List<String> locations = [];
    
    for (var bed in _beds) {
      bed.speciesMap.forEach((key, sId) {
        if (sId == speciesId) {
          final parts = key.split('-');
          final line = int.tryParse(parts[0]);
          final row = int.tryParse(parts[1]);
          locations.add(bed.formatPosition(line, row));
        }
      });
    }

    for (var crate in _crates) {
      if (crate.speciesIds.contains(speciesId)) {
        locations.add(crate.id);
      }
    }

    return locations;
  }

  @override
  Future<void> setSpeciesAtBedCell(String bedId, int line, int row, String? speciesId) async {
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

  @override
  Future<void> addSpeciesToCrate(String crateId, String speciesId) async {
    await _ensureInitialized();
    final crate = await getCrateById(crateId);
    if (crate != null && !crate.speciesIds.contains(speciesId)) {
      crate.speciesIds.add(speciesId);
      await _saveData();
    }
  }

  @override
  Future<void> removeSpeciesFromCrate(String crateId, String speciesId) async {
    await _ensureInitialized();
    final crate = await getCrateById(crateId);
    if (crate != null) {
      crate.speciesIds.remove(speciesId);
      await _saveData();
    }
  }

  @override
  Future<void> clearLocation(String id) async {
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
