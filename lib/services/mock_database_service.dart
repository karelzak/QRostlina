import '../models/species.dart';

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

  static Future<List<Species>> getAllSpecies() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network lag
    return _mockSpecies;
  }

  static Future<void> addSpecies(Species species) async {
    _mockSpecies.add(species);
  }
}
