import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final String consultationId;
  final double amount;

  const PaymentScreen({
    Key? key,
    required this.consultationId,
    this.amount = 150000.0,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const Color primaryDark = Color(0xFF2C3E35);

  late Timer _timer;
  Duration _timeLeft = const Duration(hours: 23, minutes: 59, seconds: 59);
  StreamSubscription<DocumentSnapshot>? _consultationSubscription;

  bool _isSuccess = false;

  // Link QR Code Valid untuk Midtrans Simulator
  String get _qrImageUrl =>
      'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=https://simulator.sandbox.midtrans.com/qris/index';

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _listenToPaymentStatus();
  }

  // Hitung mundur waktu kadaluarsa QRIS
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        if (mounted) {
          setState(() {
            _timeLeft = _timeLeft - const Duration(seconds: 1);
          });
        }
      } else {
        _timer.cancel();
      }
    });
  }

  // Mendengarkan perubahan data Firestore secara Real-Time (Auto Detect Payment)
  void _listenToPaymentStatus() {
    _consultationSubscription = FirebaseFirestore.instance
        .collection('consultations')
        .doc(widget.consultationId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data['status'] == 'Paid' && !_isSuccess) {
          setState(() => _isSuccess = true);
          _showSuccessDialog();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _consultationSubscription?.cancel();
    super.dispose();
  }

  // Salin Link URL QR untuk Simulator Midtrans
  void _copyQrUrl() {
    Clipboard.setData(ClipboardData(text: _qrImageUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL Gambar QRIS berhasil disalin! Silakan paste di Midtrans Simulator.'),
        backgroundColor: primaryDark,
      ),
    );
  }

  // Buka Website Midtrans Simulator
  Future<void> _openMidtransSimulator() async {
    final Uri url = Uri.parse('https://simulator.sandbox.midtrans.com/qris/index');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka halaman simulator payment.')),
      );
    }
  }

  // Simulasi Bayar Langsung (Untuk Demo Cepat)
  Future<void> _simulateSuccessfulPayment() async {
    try {
      await FirebaseFirestore.instance
          .collection('consultations')
          .doc(widget.consultationId)
          .update({
        'status': 'Paid',
        'paidAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simulasi: $e')),
      );
    }
  }

  // Pop-up Notifikasi Sukses
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 60, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaksi sebesar Rp ${widget.amount.toStringAsFixed(0)} telah terverifikasi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.popUntil(context, (route) => route.isFirst); // Kembali ke Riwayat
                },
                child: const Text('Lihat Riwayat Konsultasi', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Pembayaran QRIS',
          style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Frame Header QRIS Resmi
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Header Logo QRIS
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE11D48), // Merah QRIS
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('QRIS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.2)),
                        Text('NMID: ID1020304050', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'RuangRancang Architecture',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 4),
                        Text('Order ID: ${widget.consultationId}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        const SizedBox(height: 12),

                        // Total Harga
                        Text(
                          'Rp ${widget.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryDark),
                        ),
                        const SizedBox(height: 12),

                        // Timer Mundur
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer, size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 6),
                              Text(
                                'Batas Waktu: ${_formatDuration(_timeLeft)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Gambar QRIS
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.network(
                            _qrImageUrl,
                            width: 200,
                            height: 200,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Bisa discan menggunakan BCA, Mandiri, GoPay, OVO, ShopeePay, Dana, dll.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Alat Simulasi Demo Dosen
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Opsi Simulasi Pembayaran (Demo):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyQrUrl,
                          icon: const Icon(Icons.copy, size: 14, color: primaryDark),
                          label: const Text('Salin URL QR', style: TextStyle(fontSize: 12, color: primaryDark)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                          onPressed: _openMidtransSimulator,
                          icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
                          label: const Text('Simulator Web', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _simulateSuccessfulPayment,
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                      label: const Text('Simulasi Scan & Bayar Berhasil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}