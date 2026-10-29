import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  static const _blue = Color(0xFF2860ED);
  static const _dark = Color(0xFF19283F);
  static const _background = Color(0xFFF6F8FC);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      context.go('/home');
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal masuk. Periksa email dan kata sandimu.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: Color(0xFF7888A3),
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF98A3B5),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 22,
      ),
      suffixIcon: suffixIcon,
      border: _border(const Color(0xFFDFE6F2)),
      enabledBorder: _border(const Color(0xFFDFE6F2)),
      focusedBorder: _border(_blue),
      errorBorder: _border(Colors.redAccent),
      focusedErrorBorder: _border(Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    36,
                    24,
                    32,
                  ),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    // Judul
                    const Text(
                      'Perjalananmu,\npilihanmu.',
                      style: TextStyle(
                        color: _dark,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        letterSpacing: -0.7,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logo hanya ditampilkan di tengah.
                    Container(
                      height: 145,
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECF2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 280,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                              'Logo belum terbaca',
                              style: TextStyle(
                                color: _blue,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Masuk ke akunmu',
                      style: TextStyle(
                        color: _dark,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Temukan mobil untuk setiap rencana.',
                      style: TextStyle(
                        color: Color(0xFF8190A8),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.email,
                      ],
                      autocorrect: false,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 14,
                      ),
                      decoration: _inputDecoration(
                        label: 'Email',
                        hint: 'nama@email.com',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Email wajib diisi';
                        }

                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) {
                          return 'Masukkan email yang valid';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Kata sandi
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.password,
                      ],
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 14,
                      ),
                      decoration: _inputDecoration(
                        label: 'Kata sandi',
                        hint: 'Masukkan kata sandi',
                        suffixIcon: IconButton(
                          tooltip: _obscureText
                              ? 'Tampilkan kata sandi'
                              : 'Sembunyikan kata sandi',
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF8190A8),
                            size: 21,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi wajib diisi';
                        }

                        return null;
                      },
                      onFieldSubmitted: (_) => _login(),
                    ),

                    const SizedBox(height: 20),

                    // Tombol masuk
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFFA5BDF8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tombol daftar
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.push('/register'),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFECF2FF),
                          foregroundColor: _blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Belum punya akun? Daftar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}