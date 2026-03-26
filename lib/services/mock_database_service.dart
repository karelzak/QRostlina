import '../models/species.dart';
import '../models/plant_unit.dart';
import '../models/location.dart';

class MockDatabaseService {
  // Static mock data for development
  static final List<Species> _mockSpecies = [
    Species(
      id: 'S-001',
      name: 'Cornel Bronze',
      latinName: 'Dahlia pinnata',
      color: 'Bronze/Orange',
      height: '110 cm',
      description: 'Ball dahlia with strong stems.',
    ),
    Species(
      id: 'S-002',
      name: 'Cafe au Lait',
      latinName: 'Dahlia pinnata',
      color: 'Creamy Pink',
      height: '120 cm',
      description: 'Large decorative dinner plate dahlia.',
    ),
  ];

  static final List<PlantUnit> _mockPlants = [
    PlantUnit(id: 'P-001', speciesId: 'S-001', status: PlantStatus.inGround, locationId: 'B-01'),
    PlantUnit(id: 'P-002', speciesId: 'S-001', status: PlantStatus.inStock, locationId: 'C-01'),
    PlantUnit(id: 'P-003', speciesId: 'S-002', status: PlantStatus.inGround, locationId: 'B-01'),
  ];

  static final List<Bed> _mockBeds = [
    Bed(id: 'B-01', name: 'West Garden - Bed A', row: 'A', position: '1-10'),
    Bed(id: 'B-02', name: 'West Garden - Bed B', row: 'B', position: '11-20'),
  ];

  static final List<Crate> _mockCrates = [
    Crate(id: 'C-01', name: 'Greenhouse Crate #1', type: 'Plastic'),
    Crate(id: 'C-02', name: 'Storage Crate #2', type: 'Wooden'),
  ];

  static Future<List<Species>> getAllSpecies() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockSpecies;
  }

  static Future<Species?> getSpeciesById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockSpecies.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<PlantUnit?> getPlantById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockPlants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<Bed?> getBedById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockBeds.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<Crate?> getCrateById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockCrates.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<PlantUnit>> getPlantsByLocation(String locationId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockPlants.where((p) => p.locationId == locationId).toList();
  }

  static Future<List<PlantUnit>> getPlantsBySpecies(String speciesId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockPlants.where((p) => p.speciesId == speciesId).toList();
  }

  static Future<void> addSpecies(Species species) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockSpecies.indexWhere((s) => s.id == species.id);
    if (index >= 0) {
      _mockSpecies[index] = species;
    } else {
      _mockSpecies.add(species);
    }
  }

  static Future<void> savePlant(PlantUnit plant) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockPlants.indexWhere((p) => p.id == plant.id);
    if (index >= 0) {
      _mockPlants[index] = plant;
    } else {
      _mockPlants.add(plant);
    }
  }

  static Future<void> saveLocation(Location location) async {
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
  }
}
