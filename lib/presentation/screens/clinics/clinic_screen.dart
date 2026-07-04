import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/clinic_providers.dart';
import '../../../core/theme/app_theme.dart';

class ClinicScreen extends ConsumerStatefulWidget {
  const ClinicScreen({super.key});

  @override
  ConsumerState<ClinicScreen> createState() => _ClinicScreenState();
}

class _ClinicScreenState extends ConsumerState<ClinicScreen> {
  final MapController _mapController = MapController();
  // Lokasi default (Surakarta), tapi sekarang titik GPS-nya dipisah sedikit 
  // agar tidak menyatu 100% dengan data dummy klinik
  LatLng _currentLocation = const LatLng(-7.5650, 110.8270); 
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePosition(); 
    });
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoadingLocation = true);
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _finishLoadingAndFetch();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _finishLoadingAndFetch();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _finishLoadingAndFetch();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Gagal dapat GPS: $e");
    }

    _finishLoadingAndFetch();
  }

  void _finishLoadingAndFetch() {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = false;
    });

    // Peta sekarang SELALU ADA di layar, jadi move() pasti berhasil!
    try {
      _mapController.move(_currentLocation, 14.0);
    } catch (e) {
      debugPrint("Peta belum siap: $e");
    }

    ref.read(clinicListProvider.notifier).fetchNearbyClinics(
      _currentLocation.latitude, 
      _currentLocation.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicState = ref.watch(clinicListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Find Clinic', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isLoadingLocation 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            onPressed: _determinePosition,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ==========================================
          // 1. BAGIAN ATAS: PETA SELALU MUNCUL (STACK)
          // ==========================================
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.outlineVariant, width: 1)),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.vetcare.app',
                      ),
                      MarkerLayer(
                        markers: [
                          // Marker Biru (Lokasi Pengguna)
                          Marker(
                            point: _currentLocation,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                          ),
                          
                          // Marker Klinik (Ditarik jika data sudah ada)
                          ...(clinicState.value ?? []).map((clinic) {
                            return Marker(
                              point: LatLng(clinic.lat, clinic.lng),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(clinic.name), duration: const Duration(seconds: 2)),
                                  );
                                },
                                child: Icon(
                                  clinic.is24Hours ? Icons.local_hospital : Icons.location_on,
                                  color: clinic.is24Hours ? Colors.red : AppTheme.primary,
                                  size: 40,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                  
                  // Jika masih loading data OSM, tampilkan loading kecil di tengah peta
                  if (clinicState.isLoading)
                    Container(
                      color: Colors.white.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ==========================================
          // 2. BAGIAN BAWAH: LIST KLINIK
          // ==========================================
          Expanded(
            flex: 3,
            child: clinicState.when(
              data: (clinics) {
                if (clinics.isEmpty) {
                  return const Center(child: Text('Tidak ada klinik hewan di sekitar.'));
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
                          '${clinic.address}\n${clinic.is24Hours ? "Buka 24 Jam" : "Lihat jam buka di lokasi"}',
                          style: const TextStyle(color: AppTheme.textOnSurfaceVariant, fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.directions, color: AppTheme.secondary),
                        onTap: () {
                          try {
                            _mapController.move(LatLng(clinic.lat, clinic.lng), 17.0);
                          } catch (e) {
                            debugPrint(e.toString());
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: Text('Mencari data area sekitar...')),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}