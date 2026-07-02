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
                Icon(Icons.pets, size: 80, color: AppTheme.primary),
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
                          const SizedBox(height: 24),
                          
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