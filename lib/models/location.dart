abstract class Location {
  final String id;
  final String name;

  Location({required this.id, required this.name});
}

enum BedLayout {
  grid,   // 2 lines, X rows per meter
  linear, // 1 line, X fragments per meter
  rand,   // Random / disorganized: flat list of species, no meters
}

class Bed extends Location {
  final int length; // 10 or 20 meters
  final int linesPerMeter; // grid: 1-3, linear: 1, rand: N/A
  final int rowsPerMeter; // grid: 1-5, linear: plants per meter, rand: N/A
  final BedLayout layout;
  final String? row; // The bed's identifier in the field (e.g. "Row A")
  final Map<String, String> speciesMap; // grid: "line-row" -> speciesId, linear: "1-meter" -> speciesId
  final List<String> randSpeciesIds; // rand: flat list of speciesIds

  Bed({
    required super.id,
    required super.name,
    required this.length,
    this.linesPerMeter = 2,
    this.rowsPerMeter = 2,
    this.layout = BedLayout.grid,
    this.row,
    Map<String, String>? speciesMap,
    List<String>? randSpeciesIds,
  }) : speciesMap = speciesMap ?? {},
       randSpeciesIds = randSpeciesIds ?? [];

  int get totalLines => layout == BedLayout.grid ? linesPerMeter : 1;
  
  int get totalCells {
    if (layout == BedLayout.rand) return -1;
    return length * linesPerMeter * rowsPerMeter;
  }

  int get filledCells {
    if (layout == BedLayout.rand) return randSpeciesIds.length;
    if (layout == BedLayout.linear) {
      return speciesMap.length * linesPerMeter * rowsPerMeter;
    }
    return speciesMap.length;
  }

  bool get isConsistent => true;

  String formatPosition(int? line, int? row) {
    if (layout == BedLayout.rand) return id;
    if (row == null) return 'N/A';
    
    if (layout == BedLayout.linear) {
      return '$id-${row}M (${linesPerMeter * rowsPerMeter}pcs)';
    }

    int meter = ((row - 1) / rowsPerMeter).floor() + 1;
    String lineStr = line == 1 ? 'L' : (line == 2 ? 'R' : 'C');
    int subRow = ((row - 1) % rowsPerMeter) + 1;
    return '$id-${meter}M-$subRow$lineStr';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'length': length,
      'linesPerMeter': linesPerMeter,
      'rowsPerMeter': rowsPerMeter,
      'layout': layout.name,
      'row': row,
      'speciesMap': speciesMap,
      'randSpeciesIds': randSpeciesIds,
      'type': 'bed',
    };
  }

  factory Bed.fromMap(Map<String, dynamic> map) {
    return Bed(
      id: map['id'],
      name: map['name'],
      length: map['length'] ?? 10,
      linesPerMeter: map['linesPerMeter'] ?? 2,
      rowsPerMeter: map['rowsPerMeter'] ?? 2,
      layout: BedLayout.values.byName(map['layout'] ?? 'grid'),
      row: map['row'],
      speciesMap: Map<String, String>.from(map['speciesMap'] ?? {}),
      randSpeciesIds: List<String>.from(map['randSpeciesIds'] ?? []),
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
