import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/clinic_models.dart';
import '../../data/repositories/clinic_repostory.dart';

final clinicRepositoryProvider = Provider<ClinicRepository>((ref) {
  return ClinicRepository();
});

final clinicListProvider = StateNotifierProvider<ClinicListNotifier, AsyncValue<List<ClinicModel>>>((ref) {
  return ClinicListNotifier(ref.watch(clinicRepositoryProvider));
});

class ClinicListNotifier extends StateNotifier<AsyncValue<List<ClinicModel>>> {
  final ClinicRepository _repository;

  ClinicListNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> fetchNearbyClinics(double lat, double lng) async {
    state = const AsyncValue.loading();
    try {
      final clinics = await _repository.fetchClinicsFromOSM(lat, lng);
      state = AsyncValue.data(clinics);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}