class PlantUnit {
  final String id; // Prefix P-
  final String speciesId; // Reference to Species ID (S-)
  final String? locationId; // Reference to Bed (B-) or Crate (C-)
  final int? gridLine; // 1 or 2
  final int? gridRow;  // 1 to (length * rowsPerMeter)

  PlantUnit({
    required this.id,
    required this.speciesId,
    this.locationId,
    this.gridLine,
    this.gridRow,
  });

  String get status {
    if (locationId == null) return 'No Location';
    if (locationId!.startsWith('B-')) return 'In Bed';
    if (locationId!.startsWith('C-')) return 'In Crate';
    return 'Unknown';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'speciesId': speciesId,
      'locationId': locationId,
      'gridLine': gridLine,
      'gridRow': gridRow,
    };
  }

  factory PlantUnit.fromMap(Map<String, dynamic> map) {
    return PlantUnit(
      id: map['id'],
      speciesId: map['speciesId'],
      locationId: map['locationId'],
      gridLine: map['gridLine'],
      gridRow: map['gridRow'],
    );
  }
}
