import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clinic_models.dart';

class ClinicRepository {
  Future<List<ClinicModel>> fetchClinicsFromOSM(double lat, double lng) async {
    final query = '''
      [out:json];
      node(around:10000, $lat, $lng)["amenity"="veterinary"];
      out;
    ''';
    
    final url = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}');

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        return elements.map((e) {
          final tags = e['tags'] ?? {};
          return ClinicModel(
            id: e['id'].toString(),
            name: tags['name'] ?? 'Klinik Hewan (Tanpa Nama)',
            address: tags['addr:street'] ?? tags['addr:full'] ?? 'Detail alamat tidak tersedia di peta',
            lat: e['lat'].toDouble(),
            lng: e['lon'].toDouble(),
            phone: tags['phone'],
            is24Hours: tags['opening_hours'] == '24/7', 
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal mengambil data dari peta: $e');
    }
  }
}