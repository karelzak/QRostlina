enum PlantStatus {
  inGround,
  inStock,
  sold,
}

class PlantUnit {
  final String id; // Prefix P-
  final String speciesId; // Reference to Species ID (S-)
  final PlantStatus status;
  final String? locationId; // Reference to Bed (B-) or Crate (C-)

  PlantUnit({
    required this.id,
    required this.speciesId,
    required this.status,
    this.locationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'speciesId': speciesId,
      'status': status.name,
      'locationId': locationId,
    };
  }

  factory PlantUnit.fromMap(Map<String, dynamic> map) {
    return PlantUnit(
      id: map['id'],
      speciesId: map['speciesId'],
      status: PlantStatus.values.byName(map['status']),
      locationId: map['locationId'],
    );
  }
}
