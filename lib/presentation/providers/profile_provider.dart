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

// Provider terpisah untuk fitur "Ganti Password" di halaman Profil.
// Dibuat berdiri sendiri (bukan lewat AuthNotifier) supaya tidak memicu
// ulang authStateProvider / navigasi saat user sedang login dan cuma mau
// mengganti password-nya.
final changePasswordStateProvider =
    StateNotifierProvider.autoDispose<ChangePasswordNotifier, AsyncValue<void>>((ref) {
  return ChangePasswordNotifier();
});

class ChangePasswordNotifier extends StateNotifier<AsyncValue<void>> {
  ChangePasswordNotifier() : super(const AsyncValue.data(null));

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = await DatabaseHelper.instance.database;

      // Pastikan password lama benar sebelum diganti
      final matches = await db.query(
        'users_profile',
        where: 'id = ? AND password = ?',
        whereArgs: [userId, currentPassword],
      );

      if (matches.isEmpty) {
        throw Exception('Password lama tidak sesuai!');
      }

      await db.update(
        'users_profile',
        {'password': newPassword},
        where: 'id = ?',
        whereArgs: [userId],
      );

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void resetState() {
    state = const AsyncValue.data(null);
  }
}