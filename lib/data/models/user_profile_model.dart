class UserProfileModel {
  final String id;
  final String? name;
  final String? photoUrl;
  final String? phone;

  UserProfileModel({
    required this.id,
    this.name,
    this.photoUrl,
    this.phone,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'],
      name: json['name'],
      photoUrl: json['photo_url'],
      phone: json['phone'],
    );
  }
} 