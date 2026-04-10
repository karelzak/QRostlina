import 'dart:convert';

class PrintTemplate {
  final String id;
  final String name;
  final String localPath; // Path in app documents directory
  final String tapeSize;  // e.g., "36mm", "24mm", "12mm"

  PrintTemplate({
    required this.id,
    required this.name,
    required this.localPath,
    required this.tapeSize,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'localPath': localPath,
    'tapeSize': tapeSize,
  };

  factory PrintTemplate.fromMap(Map<String, dynamic> map) => PrintTemplate(
    id: map['id'] as String,
    name: map['name'] as String,
    localPath: map['localPath'] as String,
    tapeSize: map['tapeSize'] as String,
  );

  String toJson() => jsonEncode(toMap());
  factory PrintTemplate.fromJson(String json) =>
      PrintTemplate.fromMap(jsonDecode(json) as Map<String, dynamic>);
}
