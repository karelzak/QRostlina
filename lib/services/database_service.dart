import '../models/species.dart';
import '../models/location.dart';
import '../services/qr_scanner_service.dart';

abstract class DatabaseService {
  Future<void> initialize();
  Future<bool> isIdUnique(String id);
  Future<String> generateNextId(ScannedType type);
  Future<List<Species>> getAllSpecies();
  Future<List<Bed>> getAllBeds();
  Future<List<Crate>> getAllCrates();
  Future<Species?> getSpeciesById(String id);
  Future<Bed?> getBedById(String id);
  Future<Crate?> getCrateById(String id);
  Future<bool> speciesExists(String id);
  Future<bool> locationExists(String id);
  Future<void> addSpecies(Species species);
  Future<void> deleteSpecies(String id);
  Future<void> deleteLocation(String id);
  Future<void> saveLocation(Location location);
  Future<List<String>> getLocationsForSpecies(String speciesId);
  Future<void> setSpeciesAtBedCell(String bedId, int line, int row, String? speciesId);
  Future<void> addSpeciesToCrate(String crateId, String speciesId);
  Future<void> removeSpeciesFromCrate(String crateId, String speciesId);
  Future<void> clearLocation(String id);
  
  // Import/Export (mostly for local mode or migration)
  Future<void> exportData(String path);
  Future<void> importData(String path);
}
