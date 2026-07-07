import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _notificationService = NotificationService();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<PendingNotificationRequest> _pendingNotifications = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
    
    // Timer untuk me-refresh tampilan UI (hitung mundur) setiap 1 menit
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingNotifications() async {
    final pending = await _notificationService.getPendingNotifications();
    setState(() => _pendingNotifications = pending);
  }

  Future<void> _cancelNotification(int id) async {
    await _notificationService.cancelNotification(id);
    _loadPendingNotifications();
  }

  // Fungsi untuk mengonversi payload (tanggal ISO) menjadi teks hitung mundur
  String _getCountdownText(String? payload) {
    if (payload == null || payload.isEmpty) return 'Jadwal tidak diketahui';
    
    try {
      final targetDate = DateTime.parse(payload);
      final now = DateTime.now();
      final difference = targetDate.difference(now);

      if (difference.isNegative) return 'Waktu telah berlalu (Akan dihapus otomatis)';

      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;

      List<String> timeParts = [];
      if (days > 0) timeParts.add('$days hari');
      if (hours > 0) timeParts.add('$hours jam');
      if (minutes > 0) timeParts.add('$minutes menit');

      if (timeParts.isEmpty) return 'Berbunyi dalam waktu kurang dari 1 menit';
      
      return 'Berbunyi dalam: ${timeParts.join(', ')}';
    } catch (e) {
      return 'Format jadwal tidak valid';
    }
  }

  void _showReminderModal({PendingNotificationRequest? existingNotification}) {
    if (existingNotification != null) {
      _titleController.text = existingNotification.title ?? '';
      _bodyController.text = existingNotification.body ?? '';
      
      if (existingNotification.payload != null) {
        try {
          final savedDate = DateTime.parse(existingNotification.payload!);
          _selectedDate = savedDate;
          _selectedTime = TimeOfDay.fromDateTime(savedDate);
        } catch (e) {
          _selectedDate = DateTime.now();
          _selectedTime = TimeOfDay.now();
        }
      }
    } else {
      _titleController.clear();
      _bodyController.clear();
      _selectedDate = null;
      _selectedTime = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existingNotification == null ? 'Buat Pengingat' : 'Edit Pengingat',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul',
                  prefixIcon: const Icon(Icons.title, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: 'Catatan',
                  prefixIcon: const Icon(Icons.notes, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setModalState(() => _selectedDate = date);
                      },
                      icon: const Icon(Icons.calendar_today, color: AppTheme.primary),
                      label: Text(
                        _selectedDate == null
                            ? 'Tanggal'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: const TextStyle(color: AppTheme.textOnSurface, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) setModalState(() => _selectedTime = time);
                      },
                      icon: const Icon(Icons.access_time, color: AppTheme.primary),
                      label: Text(
                        _selectedTime == null ? 'Waktu' : _selectedTime!.format(context),
                        style: const TextStyle(color: AppTheme.textOnSurface, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty || _selectedDate == null || _selectedTime == null) return;
                  final scheduleDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _selectedTime!.hour,
                    _selectedTime!.minute,
                  );
                  if (scheduleDateTime.isBefore(DateTime.now())) return;

                  if (existingNotification != null) {
                    await _notificationService.cancelNotification(existingNotification.id);
                  }

                  final notificationId = existingNotification?.id ?? (DateTime.now().millisecondsSinceEpoch / 1000).round();
                  
                  await _notificationService.scheduleNotification(
                    id: notificationId,
                    title: _titleController.text,
                    body: _bodyController.text.isEmpty ? 'Jadwal VetCare' : _bodyController.text,
                    scheduledDate: scheduleDateTime,
                  );
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadPendingNotifications();
                },
                child: Text(existingNotification == null ? 'Jadwalkan' : 'Simpan Perubahan'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailModal(PendingNotificationRequest notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Pengingat',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Judul',
              style: TextStyle(fontSize: 12, color: AppTheme.textOnSurfaceVariant, fontWeight: FontWeight.bold),
            ),
            Text(
              notification.title ?? '',
              style: const TextStyle(fontSize: 16, color: AppTheme.textOnSurface, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Catatan',
              style: TextStyle(fontSize: 12, color: AppTheme.textOnSurfaceVariant, fontWeight: FontWeight.bold),
            ),
            Text(
              notification.body ?? '',
              style: const TextStyle(fontSize: 15, color: AppTheme.textOnSurface),
            ),
            const SizedBox(height: 16),
            const Text(
              'Status Jadwal',
              style: TextStyle(fontSize: 12, color: AppTheme.textOnSurfaceVariant, fontWeight: FontWeight.bold),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: AppTheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getCountdownText(notification.payload),
                      style: const TextStyle(fontSize: 13, color: AppTheme.secondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showReminderModal(existingNotification: notification);
                    },
                    icon: const Icon(Icons.edit, color: AppTheme.primary),
                    label: const Text('Edit', style: TextStyle(color: AppTheme.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _cancelNotification(notification.id);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    icon: const Icon(Icons.delete),
                    label: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Pengingat', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _pendingNotifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: AppTheme.outlineVariant),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada pengingat aktif',
                    style: TextStyle(color: AppTheme.textOnSurfaceVariant, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingNotifications.length,
              itemBuilder: (context, index) {
                final notification = _pendingNotifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.outlineVariant),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryContainer.withOpacity(0.2),
                      child: const Icon(Icons.alarm, color: AppTheme.primary),
                    ),
                    title: Text(
                      notification.title ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification.body ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: AppTheme.secondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _getCountdownText(notification.payload),
                                style: const TextStyle(fontSize: 12, color: AppTheme.secondary, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.primary),
                          onPressed: () => _showReminderModal(existingNotification: notification),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _cancelNotification(notification.id),
                        ),
                      ],
                    ),
                    onTap: () => _showDetailModal(notification),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showReminderModal(),
        icon: const Icon(Icons.add_alert),
        label: const Text('Buat Jadwal'),
      ),
    );
  }
}