import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'change_password_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final userState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold))),
      body: profileState.when(
        data: (profile) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.primaryContainer.withOpacity(0.2),
                backgroundImage: profile?.photoUrl != null ? FileImage(File(profile!.photoUrl!)) : null,
                child: profile?.photoUrl == null ? const Icon(Icons.person, size: 60, color: AppTheme.primary) : null,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    ListTile(leading: const Icon(Icons.person, color: AppTheme.primary), title: const Text('Nama'), subtitle: Text(profile?.name ?? '-')),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.email, color: AppTheme.primary), title: const Text('Email'), subtitle: Text(userState.value?.email ?? '-')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: const Icon(Icons.password, color: AppTheme.primary),
                title: const Text('Ganti Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const ChangePasswordDialog(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(authStateProvider.notifier).signOut(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar Akun'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}