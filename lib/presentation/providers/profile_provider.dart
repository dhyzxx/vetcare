import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile_model.dart';
import '../../core/database/database_helper.dart';
import 'auth_provider.dart';

final userProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final db = await DatabaseHelper.instance.database;
  final maps = await db.query('users_profile', where: 'id = ?', whereArgs: [user.id]);

  if (maps.isEmpty) return null;
  return UserProfileModel.fromJson(maps.first);
});