import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_background.dart';
import 'after_login.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

enum LoginMethod { email, phone }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();

  LoginMethod _method = LoginMethod.email;
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    // Login pakai No. HP → ke halaman OTP (mode Masuk)
    if (_method == LoginMethod.phone) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OtpScreen(phoneNumber: '+62${_phoneController.text.trim()}'),
        ),
      );
      return;
    }

    // Login pakai email
    setState(() => _loading = true);
    try {
      await _authService.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      await navigateAfterLogin(context);
    } catch (e) {
      _showMessage(AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Isi email kamu dulu di kolom Email.');
      return;
    }
    try {
      await _authService.sendPasswordReset(email);
      // Sengaja netral: tidak memberi tahu apakah email terdaftar atau tidak
      _showMessage(
        'Jika $email terdaftar, link reset password akan dikirim. '
            'Cek juga folder Spam.',
      );
    } catch (e) {
      _showMessage(AuthService.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogo(),
                const SizedBox(height: 40),
                Text(
                  'Selamat Datang\nKembali',
                  style: AppTheme.heading(28).copyWith(
                    color: Colors.white,
                    shadows: AppTheme.textShadow,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masuk untuk melanjutkan konsultasi desain rumah impianmu.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: AppTheme.textShadow,
                  ),
                ),
                const SizedBox(height: 28),
                _buildMethodSwitch(),
                const SizedBox(height: 24),
                if (_method == LoginMethod.email)
                  ..._buildEmailFields()
                else
                  ..._buildPhoneFields(),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _loading ? null : _onLoginPressed,
                  child: _loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Text(_method == LoginMethod.email
                      ? 'Masuk'
                      : 'Kirim Kode OTP'),
                ),
                const SizedBox(height: 24),
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Bagian-bagian kecil tampilan ----------

  Widget _buildLogo() {
    return Row(
      children: [
        const Icon(Icons.home_outlined, color: Colors.white, size: 30),
        const SizedBox(width: 8),
        Text(
          'RuangRancang',
          style: AppTheme.heading(22).copyWith(
            color: Colors.white,
            shadows: AppTheme.textShadow,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildTab('Email', LoginMethod.email),
          _buildTab('No. HP', LoginMethod.phone),
        ],
      ),
    );
  }

  Widget _buildTab(String label, LoginMethod method) {
    final selected = _method == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _method = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailFields() {
    return [
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
          if (!value.contains('@')) return 'Format email tidak valid';
          return null;
        },
      ),
      const SizedBox(height: 16),
      _label('Password'),
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: 'Masukkan password',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (value) => (value == null || value.length < 6)
            ? 'Password minimal 6 karakter'
            : null,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _onForgotPassword,
          child: const Text('Lupa password?',
              style: TextStyle(color: AppColors.primary)),
        ),
      ),
    ];
  }

  List<Widget> _buildPhoneFields() {
    return [
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
          if (value == null || value.trim().isEmpty) {
            return 'Nomor HP wajib diisi';
          }
          if (value.trim().length < 9) return 'Nomor HP tidak valid';
          return null;
        },
      ),
      const SizedBox(height: 8),
      const Text(
        'Kami akan mengirim kode OTP via SMS ke nomor ini.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    ];
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Belum punya akun? ',
              style: TextStyle(color: AppColors.textMuted)),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            child: const Text('Daftar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}