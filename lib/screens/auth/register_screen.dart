import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_background.dart';
import 'otp_screen.dart';

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
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agree = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  void _onRegisterPressed() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      _showMessage('Setujui Syarat & Ketentuan terlebih dahulu');
      return;
    }

    final phone = _phoneController.text.trim();

    // Akun BELUM dibuat di sini. Dibuat setelah OTP benar.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phoneNumber: '+62$phone',
          registration: RegistrationData(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: phone,
            password: _passwordController.text,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Buat Akun\nBaru',
                  style: AppTheme.heading(28).copyWith(
                    color: Colors.white,
                    shadows: AppTheme.textShadow,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Daftar untuk mulai konsultasi dengan arsitek RuangRancang.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: AppTheme.textShadow,
                  ),
                ),
                const SizedBox(height: 28),

                _label('Nama Lengkap'),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Nama lengkap kamu',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                  (value == null || value.trim().length < 3)
                      ? 'Nama minimal 3 huruf'
                      : null,
                ),
                const SizedBox(height: 16),

                _label('Email'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'contoh@email.com',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('Nomor HP'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '81234567890',
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+62 ',
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Nomor HP wajib diisi';
                    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                      return 'Hanya boleh angka';
                    }
                    if (v.startsWith('0')) {
                      return 'Tulis tanpa angka 0 di depan (contoh: 812...)';
                    }
                    if (v.length < 9 || v.length > 13) {
                      return 'Nomor HP tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Minimal 8 karakter',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    final v = value ?? '';
                    if (v.length < 8) return 'Password minimal 8 karakter';
                    if (!RegExp(r'[0-9]').hasMatch(v)) {
                      return 'Password harus mengandung angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('Konfirmasi Password'),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Ulangi password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'Password tidak sama'
                      : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Checkbox(
                      value: _agree,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                    ),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                          children: [
                            TextSpan(text: 'Saya menyetujui '),
                            TextSpan(
                              text: 'Syarat & Ketentuan',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: ' serta '),
                            TextSpan(
                              text: 'Kebijakan Privasi',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: ' RuangRancang.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _onRegisterPressed,
                  child: const Text('Daftar'),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sudah punya akun? ',
                          style: TextStyle(color: AppColors.textMuted)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Masuk',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}