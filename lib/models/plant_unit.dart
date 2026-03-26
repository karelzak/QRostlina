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
  final int? gridLine; // 1 or 2
  final int? gridRow;  // 1 to (length * rowsPerMeter)

  PlantUnit({
    required this.id,
    required this.speciesId,
    required this.status,
    this.locationId,
    this.gridLine,
    this.gridRow,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'speciesId': speciesId,
      'status': status.name,
      'locationId': locationId,
      'gridLine': gridLine,
      'gridRow': gridRow,
    };
  }

  factory PlantUnit.fromMap(Map<String, dynamic> map) {
    return PlantUnit(
      id: map['id'],
      speciesId: map['speciesId'],
      status: PlantStatus.values.byName(map['status']),
      locationId: map['locationId'],
      gridLine: map['gridLine'],
      gridRow: map['gridRow'],
    );
  }
}
