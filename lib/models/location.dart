abstract class Location {
  final String id;
  final String name;

  Location({required this.id, required this.name});
}

class Bed extends Location {
  final int length; // 10 or 20 meters
  final int rowsPerMeter; // 2 or 3
  final String? row; // The bed's identifier in the field (e.g. "Row A")

  Bed({
    required super.id,
    required super.name,
    required this.length,
    required this.rowsPerMeter,
    this.row,
  });

  int get totalLines => 2; // Fixed width fragmentation
  int get totalRows => length * rowsPerMeter;
  int get totalCells => totalLines * totalRows;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'length': length,
      'rowsPerMeter': rowsPerMeter,
      'row': row,
      'type': 'bed',
    };
  }

  factory Bed.fromMap(Map<String, dynamic> map) {
    return Bed(
      id: map['id'],
      name: map['name'],
      length: map['length'] ?? 10,
      rowsPerMeter: map['rowsPerMeter'] ?? 2,
      row: map['row'],
    );
  }
}

class Crate extends Location {
  final String type; // e.g., 'wooden', 'plastic'

  Crate({
    required super.id, // Prefix C-
    required super.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'locationType': 'crate',
    };
  }

  factory Crate.fromMap(Map<String, dynamic> map) {
    return Crate(
      id: map['id'],
      name: map['name'],
      type: map['type'],
    );
  }
}
