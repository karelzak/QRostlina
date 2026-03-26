class Species {
  final String id; // Prefix S-
  final String name;
  final String? latinName;
  final String? color;
  final String? description;
  final String? photoUrl;

  Species({
    required this.id,
    required this.name,
    this.latinName,
    this.color,
    this.description,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latinName': latinName,
      'color': color,
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
      description: map['description'],
      photoUrl: map['photoUrl'],
    );
  }
}
