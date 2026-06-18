import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pet_provider.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

class PetScreen extends ConsumerWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hewan Saya'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: petState.when(
        data: (pets) {
          if (pets.isEmpty) {
            return const Center(child: Text('Belum ada data hewan peliharaan.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: pet.photoUrl != null ? NetworkImage(pet.photoUrl!) : null,
                    child: pet.photoUrl == null ? const Icon(Icons.pets) : null,
                  ),
                  title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${pet.species} • ${pet.breed ?? "Unknown"}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (pet.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PetDetailScreen(pet: pet)),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPetScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}