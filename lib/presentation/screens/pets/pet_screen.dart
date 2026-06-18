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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
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
                    subtitle: Text('${pet.species} • ${pet.breed ?? "Unknown"}'),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.secondary),
                    onTap: () {
                      if (pet.id != null) Navigator.push(context, MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)));
                    },
                  ),
                );
              },
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