class Species {
  final String id; // Prefix S-
  final String name;
  final String? latinName;
  final String? color;
  final String? description;
  final String? photoUrl;
  final int rating; // 0 to 5

  Species({
    required this.id,
    required this.name,
    this.latinName,
    this.color,
    this.description,
    this.photoUrl,
    this.rating = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latinName': latinName,
      'color': color,
      'description': description,
      'photoUrl': photoUrl,
      'rating': rating,
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
      rating: map['rating'] ?? 0,
    );
  }
}
