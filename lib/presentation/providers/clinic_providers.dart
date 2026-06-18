import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/clinic_models.dart';
import '../../data/repositories/clinic_repostory.dart';

final clinicRepositoryProvider = Provider<ClinicRepository>((ref) {
  return ClinicRepository();
});

final clinicListProvider = FutureProvider<List<ClinicModel>>((ref) async {
  return ref.watch(clinicRepositoryProvider).fetchClinics();
});