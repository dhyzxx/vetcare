import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clinic_models.dart';

class ClinicRepository {
  Future<List<ClinicModel>> fetchClinicsFromOSM(double lat, double lng) async {
    // Menggunakan node, way, dan relation. Radius diperbesar jadi 15000m (15 km).
    // 'out center' digunakan untuk mengambil titik tengah dari sebuah bangunan.
    final query = '''
      [out:json];
      (
        node(around:15000, $lat, $lng)["amenity"="veterinary"];
        way(around:15000, $lat, $lng)["amenity"="veterinary"];
        relation(around:15000, $lat, $lng)["amenity"="veterinary"];
      );
      out center;
    ''';
    
    final url = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}');

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        // Jika OSM tidak memiliki data klinik sama sekali di area ini
        if (elements.isEmpty) {
          return _getFallbackData(lat, lng);
        }

        return elements.map((e) {
          final tags = e['tags'] ?? {};
          // Jika tipe data adalah 'way' atau 'relation', koordinatnya ada di 'center'
          final clinicLat = e['lat'] ?? e['center']['lat'];
          final clinicLng = e['lon'] ?? e['center']['lon'];

          return ClinicModel(
            id: e['id'].toString(),
            name: tags['name'] ?? 'Klinik Hewan (OSM)',
            address: tags['addr:street'] ?? tags['addr:full'] ?? 'Detail alamat tidak tersedia',
            lat: clinicLat.toDouble(),
            lng: clinicLng.toDouble(),
            phone: tags['phone'],
            is24Hours: tags['opening_hours'] == '24/7',
          );
        }).toList();
      }
      return _getFallbackData(lat, lng);
    } catch (e) {
      // Jika terjadi error jaringan / timeout API, gunakan fallback
      return _getFallbackData(lat, lng);
    }
  }

  // Data cadangan jika API OSM kosong atau error
  List<ClinicModel> _getFallbackData(double userLat, double userLng) {
    return [
      ClinicModel(
        id: 'fallback-1',
        name: 'Klinik Hewan Sehat Bersama (Data Lokal)',
        address: 'Jl. Slamet Riyadi No. 123, Surakarta',
        lat: -7.5666,
        lng: 110.8283,
        is24Hours: true,
      ),
      ClinicModel(
        id: 'fallback-2',
        name: 'Puskeswan Manahan (Data Lokal)',
        address: 'Jl. Adi Sucipto No. 45, Manahan',
        lat: -7.5550,
        lng: 110.8080,
        is24Hours: false,
      ),
      ClinicModel(
        id: 'fallback-3',
        name: 'Pet Care & Grooming UNS (Data Lokal)',
        address: 'Jl. Ir. Sutami No. 36, Jebres',
        lat: -7.5583,
        lng: 110.8564,
        is24Hours: false,
      ),
    ];
  }
}