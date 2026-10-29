import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const _blue = Color(0xFF2860ED);
  static const _dark = Color(0xFF19283F);
  static const _muted = Color(0xFF7888A3);
  static const _background = Color(0xFFF6F8FC);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    // Sambungkan proses pendaftaran ke AuthProvider di sini.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Isian sudah valid. Proses pendaftaran belum terhubung.',
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    List<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      autocorrect: false,
      enableSuggestions: !obscureText,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: _dark,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          color: _muted,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF8B98AD),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 22,
        ),
        border: _border(const Color(0xFFDFE6F2)),
        enabledBorder: _border(const Color(0xFFDFE6F2)),
        focusedBorder: _border(_blue),
        errorBorder: _border(Colors.redAccent),
        focusedErrorBorder: _border(Colors.redAccent),
      ),
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
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    const Text(
                      'Buat akun baru',
                      style: TextStyle(
                        color: _dark,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Mulai perjalanan pertamamu bersama NOV Rent.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildField(
                      label: 'Nama lengkap',
                      hint: 'Masukkan nama lengkap',
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Email',
                      hint: 'nama@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
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

                    _buildField(
                      label: 'Nomor telepon',
                      hint: '0812 3456 7890',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [
                        AutofillHints.telephoneNumber,
                      ],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+ ()-]'),
                        ),
                      ],
                      validator: (value) {
                        final phone = value?.trim() ?? '';

                        if (phone.isEmpty) {
                          return 'Nomor telepon wajib diisi';
                        }

                        final digits = phone.replaceAll(
                          RegExp(r'\D'),
                          '',
                        );

                        if (digits.length < 8 || digits.length > 15) {
                          return 'Masukkan nomor telepon yang valid';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Kata sandi',
                      hint: 'Minimal 8 karakter',
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [
                        AutofillHints.newPassword,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi wajib diisi';
                        }

                        if (value.length < 8) {
                          return 'Kata sandi minimal 8 karakter';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Konfirmasi kata sandi',
                      hint: 'Ulangi kata sandi',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi kata sandi wajib diisi';
                        }

                        if (value != _passwordController.text) {
                          return 'Konfirmasi kata sandi tidak sama';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Dengan mendaftar, kamu menyetujui Syarat & '
                          'Ketentuan serta Kebijakan Privasi.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Daftar sekarang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFECF2FF),
                          foregroundColor: _blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Sudah punya akun? Masuk',
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