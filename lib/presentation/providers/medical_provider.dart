import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/medical_models.dart';
import '../../data/repositories/medical_repository.dart';

final medicalRepositoryProvider = Provider<MedicalRepository>((ref) {
  return MedicalRepository();
});

final vaccinationsProvider = FutureProvider.family<List<VaccinationModel>, String>((ref, petId) async {
  return ref.watch(medicalRepositoryProvider).fetchVaccinations(petId);
});

final treatmentsProvider = FutureProvider.family<List<TreatmentModel>, String>((ref, petId) async {
  return ref.watch(medicalRepositoryProvider).fetchTreatments(petId);
});

final allergiesProvider = FutureProvider.family<List<AllergyModel>, String>((ref, petId) async {
  return ref.watch(medicalRepositoryProvider).fetchAllergies(petId);
});