import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/clinic_providers.dart';
import '../../../core/theme/app_theme.dart';

class ClinicScreen extends ConsumerWidget {
  const ClinicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicState = ref.watch(clinicListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Find Clinic', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 1. BAGIAN ATAS: UI Placeholder Peta (Bohongan)
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                border: Border(bottom: BorderSide(color: AppTheme.outlineVariant, width: 1)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ilustrasi Grid Background
                  Icon(Icons.map_outlined, size: 120, color: AppTheme.outlineVariant.withOpacity(0.3)),
                  
                  // Ilustrasi Pin Lokasi
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, size: 48, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLowest,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: const Text(
                          'Map Integration Placeholder',
                          style: TextStyle(
                            color: AppTheme.textOnSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. BAGIAN BAWAH: List Klinik dari SQLite
          Expanded(
            flex: 3,
            child: clinicState.when(
              data: (clinics) {
                if (clinics.isEmpty) {
                  return const Center(child: Text('No clinics available.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: clinics.length,
                  itemBuilder: (context, index) {
                    final clinic = clinics[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: clinic.is24Hours 
                                ? Colors.red.withOpacity(0.1) 
                                : AppTheme.primaryContainer.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            clinic.is24Hours ? Icons.local_hospital : Icons.healing,
                            color: clinic.is24Hours ? Colors.red : AppTheme.primary,
                          ),
                        ),
                        title: Text(
                          clinic.name, 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textOnSurface),
                        ),
                        subtitle: Text(
                          '${clinic.address}\n${clinic.is24Hours ? "Open 24 Hours" : ""}',
                          style: const TextStyle(color: AppTheme.textOnSurfaceVariant, fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.secondary),
                        onTap: () {
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}