import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pet_model.dart';
import '../../data/repositories/pet_repository.dart';
import 'auth_provider.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository();
});

final petListProvider = StateNotifierProvider<PetListNotifier, AsyncValue<List<PetModel>>>((ref) {
  final repository = ref.watch(petRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  return PetListNotifier(repository, user?.id);
});

class PetListNotifier extends StateNotifier<AsyncValue<List<PetModel>>> {
  final PetRepository _repository;
  final String? _userId;

  PetListNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) loadPets();
  }

  Future<void> loadPets() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final pets = await _repository.fetchPets(_userId!);
      state = AsyncValue.data(pets);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}