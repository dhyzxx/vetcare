import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  void _submitForm() async {
    // Tutup keyboard saat tombol ditekan
    FocusScope.of(context).unfocus(); 
    
    if (_formKey.currentState!.validate()) {
      if (_isLogin) {
        await ref.read(authStateProvider.notifier).signIn(_emailController.text.trim(), _passwordController.text.trim());
      } else {
        await ref.read(authStateProvider.notifier).signUp(_emailController.text.trim(), _passwordController.text.trim(), _nameController.text.trim());
      }
    }
  }

  void _showForgotPasswordDialog() {
    // Pastikan state reset password bersih setiap kali dialog dibuka
    ref.read(passwordResetStateProvider.notifier).resetState();
    showDialog(
      context: context,
      builder: (_) => const _ForgotPasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Menangkap Error dan Menampilkan SnackBar Elegan
    ref.listen<AsyncValue>(authStateProvider, (_, state) {
      if (state.hasError) {
        // Membersihkan awalan "Exception: " dari pesan error backend
        final cleanErrorMessage = state.error.toString().replaceAll('Exception: ', '');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cleanErrorMessage, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.pets, size: 80, color: AppTheme.primary),
                const SizedBox(height: 16),
                const Text('VetCare', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_isLogin ? 'Welcome Back' : 'Create Account', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController, 
                              enabled: !authState.isLoading,
                              decoration: InputDecoration(labelText: 'Full Name', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), 
                              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _emailController, 
                            enabled: !authState.isLoading,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), 
                            validator: (v) => !v!.contains('@') ? 'Email tidak valid' : null
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController, 
                            enabled: !authState.isLoading,
                            obscureText: _obscurePassword, 
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: authState.isLoading
                                    ? null
                                    : () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ), 
                            validator: (v) => v!.length < 6 ? 'Min. 6 karakter' : null
                          ),
                          if (_isLogin) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: authState.isLoading ? null : _showForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Lupa Password?', style: TextStyle(color: AppTheme.secondary, fontSize: 13)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          
                          // Tombol Loading / Submit
                          authState.isLoading 
                              ? const Center(child: CircularProgressIndicator()) 
                              : ElevatedButton(onPressed: _submitForm, child: Text(_isLogin ? 'Login' : 'Sign Up')),
                          
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: authState.isLoading ? null : () => setState(() => _isLogin = !_isLogin), 
                            child: Text(_isLogin ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk', style: const TextStyle(color: AppTheme.primary))
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Dialog form "Lupa Password": user memasukkan email + password baru.
// Menggunakan passwordResetStateProvider yang terpisah dari authStateProvider
// supaya tidak memicu navigasi/loading pada halaman utama saat dialog dibuka.
class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  const _ForgotPasswordDialog();

  @override
  ConsumerState<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref.read(passwordResetStateProvider.notifier).resetPassword(
          _emailController.text.trim(),
          _newPasswordController.text.trim(),
        );

    if (!mounted) return;
    final state = ref.read(passwordResetStateProvider);
    if (!state.hasError) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diperbarui. Silakan login.'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(passwordResetStateProvider);

    ref.listen<AsyncValue>(passwordResetStateProvider, (_, state) {
      if (state.hasError) {
        final cleanErrorMessage = state.error.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanErrorMessage, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Lupa Password'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Masukkan email akunmu dan password baru.',
                style: TextStyle(color: AppTheme.textOnSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: !resetState.isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => !v!.contains('@') ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                enabled: !resetState.isLoading,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: resetState.isLoading ? null : () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.length < 6 ? 'Min. 6 karakter' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                enabled: !resetState.isLoading,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: resetState.isLoading ? null : () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v != _newPasswordController.text ? 'Password tidak cocok' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: resetState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: resetState.isLoading ? null : _submit,
          child: resetState.isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}