import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pet_provider.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';
import '../../../core/theme/app_theme.dart';

class PetScreen extends ConsumerWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Hewan Saya', style: TextStyle(fontWeight: FontWeight.bold))),
      body: petState.when(
        data: (pets) => pets.isEmpty
          ? const Center(child: Text('Belum ada data hewan peliharaan.'))
          : RefreshIndicator(
              onRefresh: () => ref.read(petListProvider.notifier).loadPets(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index];
                  final details = [
                    pet.species,
                    if (pet.breed != null && pet.breed!.isNotEmpty) pet.breed!,
                    if (pet.gender != null) pet.gender!,
                  ].join(' • ');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.surfaceContainerLow,
                        backgroundImage: pet.photoUrl != null ? FileImage(File(pet.photoUrl!)) : null,
                        child: pet.photoUrl == null ? const Icon(Icons.pets, color: AppTheme.primary) : null,
                      ),
                      title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(details),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppTheme.secondary),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddPetScreen(existingPet: pet)),
                            );
                          } else if (value == 'detail') {
                            if (pet.id != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'detail', child: Text('Lihat Rekam Medis')),
                          PopupMenuItem(value: 'edit', child: Text('Edit Data Hewan')),
                        ],
                      ),
                      onTap: () {
                        if (pet.id != null) Navigator.push(context, MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)));
                      },
                    ),
                  );
                },
              ),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}