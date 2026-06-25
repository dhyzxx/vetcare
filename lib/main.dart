import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Notifikasi Lokal
  await NotificationService().init();

  // Inisialisasi Supabase DIHAPUS

  runApp(const ProviderScope(child: VetCareApp()));
}

class VetCareApp extends ConsumerWidget {
  const VetCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'VetCare',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainScreen();
          }
          return const AuthScreen();
        },
        loading: () => const AuthScreen(),
        error: (error, _) => const AuthScreen(),
      ),
    );
  }
}