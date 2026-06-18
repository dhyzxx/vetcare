class PetModel {
  final String? id;
  final String userId;
  final String name;
  final String species;
  final String? breed;
  final String? photoUrl;

  PetModel({
    this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    this.photoUrl,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      species: json['species'],
      breed: json['breed'],
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'photo_url': photoUrl,
    };
  }
}