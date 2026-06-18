import '../../core/database/database_helper.dart';
import '../models/clinic_models.dart';

class ClinicRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<ClinicModel>> fetchClinics() async {
    final db = await _dbHelper.database;
    final maps = await db.query('clinics');
    return maps.map((item) => ClinicModel.fromJson(item)).toList();
  }
}