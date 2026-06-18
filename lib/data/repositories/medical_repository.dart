import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../models/medical_models.dart';

class MedicalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<VaccinationModel>> fetchVaccinations(String petId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('vaccinations', where: 'pet_id = ?', whereArgs: [petId], orderBy: 'date DESC');
    return maps.map((item) => VaccinationModel.fromJson(item)).toList();
  }

  Future<List<TreatmentModel>> fetchTreatments(String petId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('treatments', where: 'pet_id = ?', whereArgs: [petId], orderBy: 'date DESC');
    return maps.map((item) => TreatmentModel.fromJson(item)).toList();
  }

  Future<List<AllergyModel>> fetchAllergies(String petId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('allergies', where: 'pet_id = ?', whereArgs: [petId], orderBy: 'created_at DESC');
    return maps.map((item) => AllergyModel.fromJson(item)).toList();
  }

  Future<void> addVaccination(VaccinationModel vaccination) async {
    final db = await _dbHelper.database;
    await db.insert('vaccinations', {
      'id': _uuid.v4(),
      'pet_id': vaccination.petId,
      'vaccine_name': vaccination.vaccineName,
      'date': vaccination.date,
      'next_schedule': vaccination.nextSchedule,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addTreatment(TreatmentModel treatment) async {
    final db = await _dbHelper.database;
    await db.insert('treatments', {
      'id': _uuid.v4(),
      'pet_id': treatment.petId,
      'date': treatment.date,
      'diagnosis': treatment.diagnosis,
      'medicine': treatment.medicine,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addAllergy(AllergyModel allergy) async {
    final db = await _dbHelper.database;
    await db.insert('allergies', {
      'id': _uuid.v4(),
      'pet_id': allergy.petId,
      'allergen': allergy.allergen,
      'reaction': allergy.reaction,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}