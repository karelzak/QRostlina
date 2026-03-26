abstract class Location {
  final String id;
  final String name;

  Location({required this.id, required this.name});
}

class Bed extends Location {
  final String? row;
  final String? position;

  Bed({
    required super.id, // Prefix B-
    required super.name,
    this.row,
    this.position,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'row': row,
      'position': position,
      'type': 'bed',
    };
  }

  factory Bed.fromMap(Map<String, dynamic> map) {
    return Bed(
      id: map['id'],
      name: map['name'],
      row: map['row'],
      position: map['position'],
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
