import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_background.dart';
import 'after_login.dart';
import 'email_verification_screen.dart';

class OtpScreen extends StatefulWidget {
  /// Nomor tujuan OTP, contoh: "+6281234567890"
  final String phoneNumber;

  /// Diisi kalau datang dari halaman Daftar. Kosong (null) = mode Masuk.
  final RegistrationData? registration;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.registration,
  });

  bool get isRegister => registration != null;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 60;

  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  final _authService = AuthService();

  Timer? _timer;
  int _secondsLeft = 0;
  String? _verificationId; // dari Firebase setelah OTP terkirim
  String? _error; // pesan error yang tampil di layar
  bool _sending = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() => setState(() {}));
    _focusNode.addListener(() => setState(() {}));
    // Kirim OTP otomatis begitu halaman tampil
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsLeft == 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  String get _timerText => '00:${_secondsLeft.toString().padLeft(2, '0')}';

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
      _otpController.clear();
    });
    try {
      final id = await _authService
          .sendOtp(widget.phoneNumber)
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      _verificationId = id;
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode OTP dikirim ke ${widget.phoneNumber}')),
      );
    } on TimeoutException {
      debugPrint('OTP ERROR: timeout, Firebase tidak menjawab dalam 30 detik');
      if (mounted) {
        setState(() => _error =
        'Firebase tidak merespons. Cek internet emulator, lalu kirim ulang kode.');
      }
    } catch (e) {
      debugPrint('OTP ERROR (kirim kode): $e');
      if (mounted) setState(() => _error = AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onVerify() async {
    final id = _verificationId;

    // Kode belum pernah berhasil dikirim → jelaskan, jangan diam saja
    if (id == null) {
      setState(() => _error ??=
      'Kode OTP belum berhasil dikirim. Klik "Kirim ulang kode".');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      if (widget.isRegister) {
        // Mode DAFTAR → buat akun, lalu ke halaman Cek Email
        await _authService.registerWithPhoneOtp(
          verificationId: id,
          smsCode: _otpController.text,
          data: widget.registration!,
        );
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
              (route) => false,
        );
      } else {
        // Mode MASUK → login, lalu pos pemeriksaan
        await _authService.loginWithOtp(
          verificationId: id,
          smsCode: _otpController.text,
        );
        if (!mounted) return;
        await navigateAfterLogin(context);
      }
    } catch (e) {
      debugPrint('OTP ERROR (verifikasi): $e');
      if (mounted) setState(() => _error = AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aktif begitu 6 digit terisi. Kalau ada masalah, pesannya muncul setelah diklik.
    final canVerify =
        _otpController.text.length == _otpLength && !_verifying && !_sending;

    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Verifikasi\nNomor HP',
                style: AppTheme.heading(28).copyWith(
                  color: Colors.white,
                  shadows: AppTheme.textShadow,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan 6 digit kode yang kami kirim via SMS ke '
                    '${widget.phoneNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: AppTheme.textShadow,
                ),
              ),
              const SizedBox(height: 48),
              _buildOtpBoxes(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorBox(_error!),
              ],
              const SizedBox(height: 24),
              Center(child: _buildResend()),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: canVerify ? _onVerify : null,
                child: _verifying
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Verifikasi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResend() {
    if (_sending) {
      return const Text('Mengirim kode...',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13));
    }
    if (_secondsLeft > 0) {
      return Text('Kirim ulang kode dalam $_timerText',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13));
    }
    return TextButton(
      onPressed: _sendCode,
      child: const Text(
        'Kirim ulang kode',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// 6 kotak OTP. Trik: 1 kolom input tersembunyi menerima ketikan,
  /// lalu tiap angkanya ditampilkan di kotak masing-masing.
  Widget _buildOtpBoxes() {
    final code = _otpController.text;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _otpController,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: _otpLength,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, (i) {
              final filled = i < code.length;
              final active = i == code.length && _focusNode.hasFocus;
              return Container(
                width: 46,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (filled || active)
                        ? AppColors.primary
                        : AppColors.border,
                    width: active ? 2 : 1,
                  ),
                ),
                child: Text(filled ? code[i] : '',
                    style: AppTheme.heading(22)),
              );
            }),
          ),
        ],
      ),
    );
  }
}