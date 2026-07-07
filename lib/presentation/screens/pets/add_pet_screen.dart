import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pet_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';

/// Form untuk menambah ATAU mengedit data hewan.
/// Jika [existingPet] diisi, maka form akan berjalan dalam mode edit
/// (field ter-prefill, tombol simpan memanggil updatePet, dan muncul
/// opsi hapus data).
class AddPetScreen extends ConsumerStatefulWidget {
  final PetModel? existingPet;

  const AddPetScreen({super.key, this.existingPet});

  bool get isEditMode => existingPet != null;

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _speciesController;
  late final TextEditingController _breedController;
  late final TextEditingController _weightController;

  DateTime? _birthDate;
  String? _gender;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isDeleting = false;

  static const _genderOptions = ['Jantan', 'Betina'];

  @override
  void initState() {
    super.initState();
    final pet = widget.existingPet;
    _nameController = TextEditingController(text: pet?.name ?? '');
    _speciesController = TextEditingController(text: pet?.species ?? '');
    _breedController = TextEditingController(text: pet?.breed ?? '');
    _weightController = TextEditingController(
      text: pet?.weight != null ? pet!.weight!.toString() : '',
    );
    _gender = pet?.gender;
    if (pet?.birthDate != null && pet!.birthDate!.isNotEmpty) {
      _birthDate = DateTime.tryParse(pet.birthDate!);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 40),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submitPetData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser == null) throw Exception('User not found');

      final weightText = _weightController.text.trim();
      final double? weight = weightText.isEmpty ? null : double.tryParse(weightText);

      if (widget.isEditMode) {
        final updatedPet = widget.existingPet!.copyWith(
          name: _nameController.text.trim(),
          species: _speciesController.text.trim(),
          breed: _breedController.text.trim(),
          birthDate: _birthDate?.toIso8601String().split('T')[0],
          gender: _gender,
          weight: weight,
        );
        await ref.read(petListProvider.notifier).updatePet(updatedPet, _selectedImage);
      } else {
        final newPet = PetModel(
          userId: currentUser.id,
          name: _nameController.text.trim(),
          species: _speciesController.text.trim(),
          breed: _breedController.text.trim(),
          birthDate: _birthDate?.toIso8601String().split('T')[0],
          gender: _gender,
          weight: weight,
        );
        await ref.read(petRepositoryProvider).addPet(newPet, _selectedImage);
        ref.read(petListProvider.notifier).loadPets();
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Hewan?'),
        content: Text(
          'Data ${widget.existingPet!.name} beserta seluruh riwayat vaksin, '
          'pengobatan, dan alerginya akan dihapus permanen. Lanjutkan?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(petListProvider.notifier).deletePet(widget.existingPet!.id!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.existingPet;
    final isBusy = _isLoading || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Hewan' : 'Tambah Hewan'),
        actions: [
          if (widget.isEditMode)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Hapus Hewan',
              onPressed: isBusy ? null : _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (pet?.photoUrl != null ? FileImage(File(pet!.photoUrl!)) : null) as ImageProvider?,
                  child: _selectedImage == null && pet?.photoUrl == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Hewan'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(labelText: 'Spesies (Contoh: Kucing, Anjing)'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Ras (Contoh: Persia, Golden)'),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir (Opsional)',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Pilih tanggal'
                        : _birthDate!.toIso8601String().split('T')[0],
                    style: TextStyle(
                      color: _birthDate == null ? Colors.grey[600] : AppTheme.textOnSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Jenis Kelamin (Opsional)'),
                items: _genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _gender = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Berat Badan / kg (Opsional)'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  return double.tryParse(val.trim()) == null ? 'Masukkan angka yang valid' : null;
                },
              ),
              const SizedBox(height: 32),
              isBusy
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitPetData,
                      child: Text(widget.isEditMode ? 'Simpan Perubahan' : 'Simpan Data Hewan'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}