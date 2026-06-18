class ClinicModel {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? phone;
  final bool is24Hours;
  final double? rating;

  ClinicModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.phone,
    required this.is24Hours,
    this.rating,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      phone: json['phone'],
      is24Hours: (json['is_24_hours'] as int) == 1,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
    );
  }
}