import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../models/pet_model.dart';

class PetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<PetModel>> fetchPets(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'pets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((item) => PetModel.fromJson(item)).toList();
  }

  Future<void> addPet(PetModel pet, File? imageFile) async {
    String? localImagePath;

    // Simpan gambar secara lokal jika ada
    if (imageFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_uuid.v4()}${p.extension(imageFile.path)}';
      final savedImage = await imageFile.copy('${directory.path}/$fileName');
      localImagePath = savedImage.path;
    }

    final db = await _dbHelper.database;
    final petData = pet.toJson();
    petData['id'] = _uuid.v4(); // Generate UUID lokal
    petData['photo_url'] = localImagePath;
    petData['created_at'] = DateTime.now().toIso8601String();

    await db.insert('pets', petData);
  }
}