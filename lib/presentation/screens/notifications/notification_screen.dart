import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _notificationService = NotificationService();

  void _triggerInstantNotification() {
    _notificationService.showInstantNotification(
      id: 1,
      title: 'Jadwal Grooming! ✂️',
      body: 'Waktunya memandikan anabul kesayangan Anda hari ini.',
    );
  }

  void _scheduleFutureNotification() {
    // Jadwalkan notifikasi 5 detik dari sekarang untuk simulasi
    final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
    
    _notificationService.scheduleNotification(
      id: 2,
      title: 'Pengingat Vaksin 💉',
      body: 'Besok jadwal vaksin rabies untuk hewan Anda di klinik terdekat.',
      scheduledDate: scheduledTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengingat diatur untuk 5 detik ke depan!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Pengingat'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Uji Coba Notifikasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _triggerInstantNotification,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Kirim Notifikasi Sekarang'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scheduleFutureNotification,
              icon: const Icon(Icons.schedule),
              label: const Text('Jadwalkan Pengingat (5 Detik)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Text(
                  'Nantinya riwayat pengingat yang tersimpan di Supabase akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}