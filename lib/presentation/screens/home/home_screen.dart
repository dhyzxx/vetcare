import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../providers/pet_provider.dart';
import '../../providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/notification_service.dart';
import '../pets/add_pet_screen.dart';
import '../pets/pet_detail_screen.dart';
import '../clinics/clinic_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<PendingNotificationRequest> _activeReminders = [];

  @override
  void initState() {
    super.initState();
    _fetchActiveReminders();
  }

  // Fungsi untuk menarik data alarm/notifikasi yang sedang antre
  Future<void> _fetchActiveReminders() async {
    final pending = await NotificationService().getPendingNotifications();
    if (mounted) {
      setState(() {
        _activeReminders = pending;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final petState = ref.watch(petListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 80,
        title: profileState.when(
          data: (profile) => Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryContainer, width: 2),
                  image: profile?.photoUrl != null
                      ? DecorationImage(
                          image: FileImage(File(profile!.photoUrl!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile?.photoUrl == null
                    ? const Icon(Icons.person, color: AppTheme.primary)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello,',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textOnSurfaceVariant,
                    ),
                  ),
                  Text(
                    profile?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('VetCare'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu Pengaturan belum tersedia untuk MVP ini.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Tambahkan RefreshIndicator agar bisa update list notifikasi dengan di-swipe ke bawah
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.read(petListProvider.notifier).loadPets();
          await _fetchActiveReminders();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Access Section
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    _buildQuickActionCard(
                      icon: Icons.add_circle,
                      label: 'Add Record',
                      iconColor: AppTheme.onPrimaryContainer,
                      bgColor: AppTheme.primaryContainer,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetScreen())),
                    ),
                    const SizedBox(width: 16),
                    _buildQuickActionCard(
                      icon: Icons.medical_services,
                      label: 'Find Clinic',
                      iconColor: Colors.white,
                      bgColor: AppTheme.tertiaryContainer,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClinicScreen())),
                    ),
                    const SizedBox(width: 16),
                    _buildQuickActionCard(
                      icon: Icons.content_cut,
                      label: 'Grooming',
                      iconColor: AppTheme.primary,
                      bgColor: AppTheme.primaryContainer.withOpacity(0.2),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur reservasi Grooming akan segera hadir!')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // My Pets Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Pets',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textOnSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Silakan gunakan tab "Pets" di menu bawah.')),
                        );
                      },
                      child: const Text(
                        'View all',
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              
              petState.when(
                data: (pets) {
                  if (pets.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: Text('Belum ada hewan peliharaan.')),
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: pets.map((pet) => _buildPetCard(pet)).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),

              // Upcoming Reminders Section (Data Asli)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Text(
                  'Upcoming Reminders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textOnSurface,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _activeReminders.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('Tidak ada jadwal pengingat aktif.', textAlign: TextAlign.center),
                      )
                    : Column(
                        children: _activeReminders.map((notif) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildReminderCard(
                              title: notif.title ?? 'Pengingat',
                              body: notif.body ?? '',
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceContainerLow),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textOnSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(dynamic pet) {
    return GestureDetector(
      onTap: () {
        if (pet.id != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)));
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceContainerLow),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.surfaceContainerLow,
                image: pet.photoUrl != null
                    ? DecorationImage(
                        image: FileImage(File(pet.photoUrl!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: pet.photoUrl == null
                  ? const Icon(Icons.pets, size: 40, color: AppTheme.outlineVariant)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              pet.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textOnSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              pet.breed ?? pet.species,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textOnSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceContainerLow),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.tertiaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.notifications_active, color: AppTheme.tertiary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}