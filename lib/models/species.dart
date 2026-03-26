class Species {
  final String id; // Prefix S-
  final String name;
  final String? latinName;
  final String? color;
  final String? height;
  final String? description;
  final String? photoUrl;

  Species({
    required this.id,
    required this.name,
    this.latinName,
    this.color,
    this.height,
    this.description,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latinName': latinName,
      'color': color,
      'height': height,
      'description': description,
      'photoUrl': photoUrl,
    };
  }

  factory Species.fromMap(Map<String, dynamic> map) {
    return Species(
      id: map['id'],
      name: map['name'],
      latinName: map['latinName'],
      color: map['color'],
      height: map['height'],
      description: map['description'],
      photoUrl: map['photoUrl'],
    );
  }
}
