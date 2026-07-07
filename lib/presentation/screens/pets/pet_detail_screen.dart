import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/medical_models.dart';
import '../../providers/medical_provider.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  final PetModel pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fieldOneController = TextEditingController(); // Digunakan untuk Nama Vaksin / Diagnosis / Alergen
  final _fieldTwoController = TextEditingController(); // Digunakan untuk Tanggal / Obat / Reaksi

  bool _isLoading = false;

  void _showAddModal(BuildContext context, String type) {
    _fieldOneController.clear();
    _fieldTwoController.clear();
    
    // Set default date if needed
    if (type == 'Vaccine' || type == 'Treatment') {
      _fieldTwoController.text = DateTime.now().toString().split(' ')[0];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tambah $type',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fieldOneController,
                decoration: InputDecoration(
                  labelText: type == 'Vaccine' 
                      ? 'Nama Vaksin' 
                      : type == 'Treatment' 
                          ? 'Diagnosis' 
                          : 'Alergen (Penyebab)',
                ),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fieldTwoController,
                decoration: InputDecoration(
                  labelText: type == 'Vaccine' 
                      ? 'Tanggal (YYYY-MM-DD)' 
                      : type == 'Treatment' 
                          ? 'Obat (Opsional)' 
                          : 'Reaksi',
                ),
                validator: (val) => val!.isEmpty && type != 'Treatment' ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () => _submitData(type),
                      child: const Text('Simpan'),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitData(String type) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final repository = ref.read(medicalRepositoryProvider);

        if (type == 'Vaccine') {
          final model = VaccinationModel(
            petId: widget.pet.id!,
            vaccineName: _fieldOneController.text.trim(),
            date: _fieldTwoController.text.trim(),
          );
          await repository.addVaccination(model);
          ref.invalidate(vaccinationsProvider(widget.pet.id!));
        } 
        else if (type == 'Treatment') {
          final model = TreatmentModel(
            petId: widget.pet.id!,
            date: _fieldTwoController.text.trim().isEmpty 
                ? DateTime.now().toString().split(' ')[0] 
                : _fieldTwoController.text.trim(),
            diagnosis: _fieldOneController.text.trim(),
            medicine: _fieldTwoController.text.trim(),
          );
          await repository.addTreatment(model);
          ref.invalidate(treatmentsProvider(widget.pet.id!));
        } 
        else if (type == 'Allergy') {
          final model = AllergyModel(
            petId: widget.pet.id!,
            allergen: _fieldOneController.text.trim(),
            reaction: _fieldTwoController.text.trim(),
          );
          await repository.addAllergy(model);
          ref.invalidate(allergiesProvider(widget.pet.id!));
        }

        if (mounted) Navigator.pop(context); // Tutup bottom sheet
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fieldOneController.dispose();
    _fieldTwoController.dispose();
    super.dispose();
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(pet.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Vaksin'),
              Tab(text: 'Pengobatan'),
              Tab(text: 'Alergi'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.pets, pet.breed?.isNotEmpty == true ? pet.breed! : pet.species),
                  if (pet.gender != null) _buildInfoChip(Icons.wc, pet.gender!),
                  if (pet.birthDate != null && pet.birthDate!.isNotEmpty)
                    _buildInfoChip(Icons.cake, 'Umur: ${pet.ageLabel}'),
                  if (pet.weight != null) _buildInfoChip(Icons.monitor_weight, '${pet.weight} kg'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildVaccinationTab(ref, widget.pet.id!),
                  _buildTreatmentTab(ref, widget.pet.id!),
                  _buildAllergyTab(ref, widget.pet.id!),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) => FloatingActionButton(
            onPressed: () {
              // Deteksi tab mana yang sedang aktif untuk menentukan form apa yang dibuka
              final tabIndex = DefaultTabController.of(ctx).index;
              String type = 'Vaccine';
              if (tabIndex == 1) type = 'Treatment';
              if (tabIndex == 2) type = 'Allergy';
              
              _showAddModal(context, type);
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildVaccinationTab(WidgetRef ref, String petId) {
    final asyncData = ref.watch(vaccinationsProvider(petId));
    return asyncData.when(
      data: (vaccines) => vaccines.isEmpty
          ? const Center(child: Text('Belum ada data vaksin'))
          : ListView.builder(
              itemCount: vaccines.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(vaccines[i].vaccineName),
                subtitle: Text('Tanggal: ${vaccines[i].date}'),
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTreatmentTab(WidgetRef ref, String petId) {
    final asyncData = ref.watch(treatmentsProvider(petId));
    return asyncData.when(
      data: (treatments) => treatments.isEmpty
          ? const Center(child: Text('Belum ada data pengobatan'))
          : ListView.builder(
              itemCount: treatments.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(treatments[i].diagnosis),
                subtitle: Text('Obat: ${treatments[i].medicine ?? "-"}'),
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAllergyTab(WidgetRef ref, String petId) {
    final asyncData = ref.watch(allergiesProvider(petId));
    return asyncData.when(
      data: (allergies) => allergies.isEmpty
          ? const Center(child: Text('Belum ada data alergi'))
          : ListView.builder(
              itemCount: allergies.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(allergies[i].allergen),
                subtitle: Text('Reaksi: ${allergies[i].reaction}'),
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}