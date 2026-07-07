class PetModel {
  final String? id;
  final String userId;
  final String name;
  final String species;
  final String? breed;
  final String? birthDate;
  final String? gender;
  final double? weight;
  final String? photoUrl;

  PetModel({
    this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    this.birthDate,
    this.gender,
    this.weight,
    this.photoUrl,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      species: json['species'],
      breed: json['breed'],
      birthDate: json['birth_date'],
      gender: json['gender'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'birth_date': birthDate,
      'gender': gender,
      'weight': weight,
      'photo_url': photoUrl,
    };
  }

  PetModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? species,
    String? breed,
    String? birthDate,
    String? gender,
    double? weight,
    String? photoUrl,
  }) {
    return PetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  /// Menghitung umur hewan dari birthDate, dalam format ringkas (tahun/bulan).
  String get ageLabel {
    if (birthDate == null || birthDate!.isEmpty) return '-';
    try {
      final birth = DateTime.parse(birthDate!);
      final now = DateTime.now();
      int months = (now.year - birth.year) * 12 + (now.month - birth.month);
      if (now.day < birth.day) months -= 1;
      if (months < 0) return '-';
      if (months < 12) return '$months bln';
      final years = months ~/ 12;
      final remMonths = months % 12;
      return remMonths == 0 ? '$years thn' : '$years thn $remMonths bln';
    } catch (_) {
      return '-';
    }
  }
}