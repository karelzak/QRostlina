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
  final Map<String, String> speciesMap; // "line-row" -> speciesId

  Bed({
    required super.id,
    required super.name,
    required this.length,
    this.rowsPerMeter = 2,
    this.layout = BedLayout.grid,
    this.row,
    Map<String, String>? speciesMap,
  }) : speciesMap = speciesMap ?? {};

  int get totalLines => 2; // Always 2 lines (Left/Right)
  int get rowsPerMeterEffective => layout == BedLayout.grid ? rowsPerMeter : 1;
  int get totalRows => length * rowsPerMeterEffective;
  int get totalCells => totalLines * totalRows;

  bool get isConsistent {
    if (layout == BedLayout.linear && totalLines > 1) return false;
    return true;
  }

  String formatPosition(int? line, int? row) {
    if (row == null) return 'N/A';
    
    int meter = ((row - 1) / rowsPerMeterEffective).floor() + 1;
    String lineStr = line == 1 ? 'L' : 'R';

    if (layout == BedLayout.linear) {
      return '$id-${meter}M-$lineStr';
    }

    int subRow = ((row - 1) % rowsPerMeterEffective) + 1;
    return '$id-${meter}M-$subRow$lineStr';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'length': length,
      'rowsPerMeter': rowsPerMeter,
      'layout': layout.name,
      'row': row,
      'speciesMap': speciesMap,
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
      speciesMap: Map<String, String>.from(map['speciesMap'] ?? {}),
    );
  }
}

class Crate extends Location {
  final String type; // e.g., 'wooden', 'plastic'
  final List<String> speciesIds;

  Crate({
    required super.id, // Prefix C-
    required super.name,
    required this.type,
    List<String>? speciesIds,
  }) : speciesIds = speciesIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'speciesIds': speciesIds,
      'locationType': 'crate',
    };
  }

  factory Crate.fromMap(Map<String, dynamic> map) {
    return Crate(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      speciesIds: List<String>.from(map['speciesIds'] ?? []),
    );
  }
}
