import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();
  static const String _sessionKey = 'user_session_id';

  Future<UserModel> signInWithEmail(String email, String password) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users_profile',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      final userData = maps.first;
      final user = UserModel(
        id: userData['id'] as String,
        email: userData['email'] as String,
        name: userData['name'] as String,
      );
      await _saveSession(user.id);
      return user;
    } else {
      throw Exception('Email atau password salah!');
    }
  }

  Future<UserModel> signUpWithEmail(String email, String password, String name) async {
    final db = await _dbHelper.database;
    
    // Cek apakah email sudah terdaftar
    final existing = await db.query(
      'users_profile', 
      where: 'email = ?', 
      whereArgs: [email],
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Email sudah terdaftar!');
    }

    final userId = _uuid.v4();
    await db.insert('users_profile', {
      'id': userId,
      'email': email,
      'password': password,
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });

    final user = UserModel(id: userId, email: email, name: name);
    await _saveSession(userId);
    return user;
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final db = await _dbHelper.database;

    // Pastikan email terdaftar sebelum reset password
    final existing = await db.query(
      'users_profile',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existing.isEmpty) {
      throw Exception('Email tidak terdaftar!');
    }

    await db.update(
      'users_profile',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_sessionKey);

    if (userId != null) {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'users_profile', 
        where: 'id = ?', 
        whereArgs: [userId],
      );
      
      if (maps.isNotEmpty) {
        final userData = maps.first;
        return UserModel(
          id: userData['id'] as String,
          email: userData['email'] as String,
          name: userData['name'] as String,
        );
      }
    }
    return null;
  }

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, userId);
  }
}