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

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    final pending = await _notificationService.getPendingNotifications();
    setState(() => _pendingNotifications = pending);
  }

  Future<void> _cancelNotification(int id) async {
    await _notificationService.cancelNotification(id);
    _loadPendingNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengingat dibatalkan.')),
      );
    }
  }

  void _showAddReminderModal() {
    _titleController.clear();
    _bodyController.clear();
    _selectedDate = null;
    _selectedTime = null;

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
              const Text('Buat Pengingat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Judul (Contoh: Vaksin)', prefixIcon: const Icon(Icons.title, color: AppTheme.primary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(labelText: 'Catatan', prefixIcon: const Icon(Icons.notes, color: AppTheme.primary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (date != null) setModalState(() => _selectedDate = date);
                      },
                      icon: const Icon(Icons.calendar_today, color: AppTheme.primary),
                      label: Text(_selectedDate == null ? 'Tanggal' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}', style: const TextStyle(color: AppTheme.textOnSurface)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) setModalState(() => _selectedTime = time);
                      },
                      icon: const Icon(Icons.access_time, color: AppTheme.primary),
                      label: Text(_selectedTime == null ? 'Waktu' : _selectedTime!.format(context), style: const TextStyle(color: AppTheme.textOnSurface)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isEmpty || _selectedDate == null || _selectedTime == null) return;
                  final scheduleDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
                  if (scheduleDateTime.isBefore(DateTime.now())) return;

                  final notificationId = (DateTime.now().millisecondsSinceEpoch / 1000).round();
                  _notificationService.scheduleNotification(id: notificationId, title: _titleController.text, body: _bodyController.text.isEmpty ? 'Jadwal VetCare' : _bodyController.text, scheduledDate: scheduleDateTime);
                  Navigator.pop(context);
                  _loadPendingNotifications();
                },
                child: const Text('Jadwalkan'),
              ),
              const SizedBox(height: 24),
            ],
          ),
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
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_off_outlined, size: 80, color: AppTheme.outlineVariant), const SizedBox(height: 16), const Text('Tidak ada pengingat aktif', style: TextStyle(color: AppTheme.textOnSurfaceVariant, fontSize: 16))]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingNotifications.length,
              itemBuilder: (context, index) {
                final notif = _pendingNotifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppTheme.primaryContainer.withOpacity(0.2), child: const Icon(Icons.alarm, color: AppTheme.primary)),
                    title: Text(notif.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(notif.body ?? ''),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _cancelNotification(notif.id)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddReminderModal,
        icon: const Icon(Icons.add_alert),
        label: const Text('Buat Jadwal'),
      ),
    );
  }
}