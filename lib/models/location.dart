abstract class Location {
  final String id;
  final String name;

  Location({required this.id, required this.name});
}

enum BedLayout {
  grid,   // 2 lines, X rows per meter
  linear, // Just meters, no sub-grid
}

class Bed extends Location {
  final int length; // 10 or 20 meters
  final int rowsPerMeter; // 2 or 3 (ignored if linear)
  final BedLayout layout;
  final String? row; // The bed's identifier in the field (e.g. "Row A")

  Bed({
    required super.id,
    required super.name,
    required this.length,
    this.rowsPerMeter = 2,
    this.layout = BedLayout.grid,
    this.row,
  });

  int get totalLines => 2; // Always 2 lines (Left/Right)
  int get rowsPerMeterEffective => layout == BedLayout.grid ? rowsPerMeter : 1;
  int get totalRows => length * rowsPerMeterEffective;
  int get totalCells => totalLines * totalRows;

  String formatPosition(int? line, int? row) {
    if (row == null) return 'N/A';
    
    int meter = ((row - 1) / rowsPerMeterEffective).floor() + 1;
    String lineStr = line == 1 ? 'Left' : 'Right';

    if (layout == BedLayout.linear) {
      return '${this.row ?? id}-$lineStr-${meter}m';
    }

    int subRow = ((row - 1) % rowsPerMeterEffective) + 1;
    return '${this.row ?? id}-$lineStr-${meter}m-$subRow';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'length': length,
      'rowsPerMeter': rowsPerMeter,
      'layout': layout.name,
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
      layout: BedLayout.values.byName(map['layout'] ?? 'grid'),
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
