import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/pengaturan.dart';
import '../../services/auth_service.dart';
import '../../services/pengaturan_service.dart';
import '../../theme/app_theme.dart';
import 'admin_ringkasan.dart'; // AdminColors
import 'admin_widgets.dart';

/// Halaman admin untuk mengubah angka & aturan yang dipakai seluruh aplikasi.
class AdminPengaturanPage extends StatefulWidget {
  const AdminPengaturanPage({super.key});

  @override
  State<AdminPengaturanPage> createState() => _AdminPengaturanPageState();
}

class _AdminPengaturanPageState extends State<AdminPengaturanPage> {
  static const _namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  final _formKey = GlobalKey<FormState>();
  final _harga = TextEditingController();
  final _durasi = TextEditingController();
  final _batasBayar = TextEditingController();
  final _bookingFee = TextEditingController();
  final _bankNama = TextEditingController();
  final _bankNomor = TextEditingController();
  final _bankAtasNama = TextEditingController();

  List<String> _slotJam = []; // contoh: ["09:00-11:00", ...]
  List<int> _hari = []; // 1 = Senin ... 7 = Minggu

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PengaturanService.ambil();
    if (!mounted) return;
    _harga.text = '${p.hargaKonsultasi}';
    _durasi.text = p.durasiKonsultasi;
    _batasBayar.text = '${p.batasBayarJam}';
    _bookingFee.text = '${p.bookingFeeRumah}';
    _bankNama.text = p.bankNama;
    _bankNomor.text = p.bankNomor;
    _bankAtasNama.text = p.bankAtasNama;
    setState(() {
      _slotJam = [...p.slotJam]..sort();
      _hari = [...p.hariOperasional]..sort();
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _harga, _durasi, _batasBayar, _bookingFee,
      _bankNama, _bankNomor, _bankAtasNama,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  // ===================== SLOT JAM =====================

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _menit(TimeOfDay t) => t.hour * 60 + t.minute;

  /// "09:00-11:00" → [540, 660] (menit sejak tengah malam)
  List<int> _rentang(String slot) {
    final bagian = slot.split('-');
    int keMenit(String hhmm) {
      final p = hhmm.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }
    return [keMenit(bagian[0]), keMenit(bagian[1])];
  }

  Future<TimeOfDay?> _pilihJam(TimeOfDay awal, String judul) {
    return showTimePicker(
      context: context,
      initialTime: awal,
      helpText: judul,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  Future<void> _tambahSlot() async {
    final mulai =
    await _pilihJam(const TimeOfDay(hour: 9, minute: 0), 'JAM MULAI');
    if (mulai == null || !mounted) return;

    final selesai = await _pilihJam(
      TimeOfDay(hour: (mulai.hour + 2) % 24, minute: mulai.minute),
      'JAM SELESAI',
    );
    if (selesai == null || !mounted) return;

    if (_menit(selesai) <= _menit(mulai)) {
      _pesan('Jam selesai harus setelah jam mulai.');
      return;
    }

    final baruMulai = _menit(mulai);
    final baruSelesai = _menit(selesai);
    for (final s in _slotJam) {
      final r = _rentang(s);
      if (baruMulai < r[1] && baruSelesai > r[0]) {
        _pesan('Bertabrakan dengan slot ${s.replaceAll('-', '–')}.');
        return;
      }
    }

    setState(() {
      _slotJam.add('${_fmt(mulai)}-${_fmt(selesai)}');
      _slotJam.sort();
    });
  }

  // ===================== SIMPAN =====================

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hari.isEmpty) {
      _pesan('Pilih minimal 1 hari operasional.');
      return;
    }
    if (_slotJam.isEmpty) {
      _pesan('Tambahkan minimal 1 slot jam.');
      return;
    }

    setState(() => _saving = true);
    try {
      await PengaturanService.simpan(Pengaturan(
        hargaKonsultasi: int.parse(_harga.text),
        durasiKonsultasi: _durasi.text.trim(),
        batasBayarJam: int.parse(_batasBayar.text),
        bookingFeeRumah: int.parse(_bookingFee.text),
        bankNama: _bankNama.text.trim(),
        bankNomor: _bankNomor.text.trim(),
        bankAtasNama: _bankAtasNama.text.trim(),
        slotJam: _slotJam,
        hariOperasional: _hari,
      ));
      if (mounted) _pesan('Pengaturan berhasil disimpan');
    } catch (e) {
      if (mounted) _pesan(AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ===================== TAMPILAN =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const AdminPageHeader(
                icon: Icons.home_work_rounded,
                judul: 'Pengaturan Aplikasi',
                subjudul:
                'Kelola informasi dan preferensi aplikasi dengan mudah.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _seksiKonsultasi(),
                    _seksiJadwal(),
                    _seksiPerumahan(),
                    _seksiRekening(),
                    const Text(
                      'Perubahan berlaku untuk semua pengguna setelah '
                          'menekan Simpan.',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saving ? null : _simpan,
                      child: _saving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Simpan Pengaturan'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Kartu-kartu bagian ----------

  Widget _seksiKonsultasi() {
    return AdminSection(
      icon: Icons.co_present_outlined,
      judul: 'Konsultasi Desain',
      children: [
        AdminFieldRow(
          icon: Icons.payments_outlined,
          label: 'Harga Konsultasi',
          child: _kolomAngka(_harga, 'Harga konsultasi', prefix: 'Rp '),
        ),
        AdminFieldRow(
          icon: Icons.schedule,
          label: 'Durasi',
          child: _kolomTeks(_durasi, 'Durasi', contoh: '2 jam'),
        ),
        AdminFieldRow(
          icon: Icons.event_outlined,
          label: 'Batas waktu bayar',
          child: _kolomAngka(_batasBayar, 'Batas waktu bayar', suffix: 'jam'),
        ),
      ],
    );
  }

  Widget _seksiJadwal() {
    return AdminSection(
      icon: Icons.groups_outlined,
      judul: 'Jadwal Konsultasi',
      children: [
        _subjudul('Hari operasional'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 1; i <= 7; i++)
              AdminPilihChip(
                label: _namaHari[i - 1],
                aktif: _hari.contains(i),
                onTap: () => setState(() {
                  _hari.contains(i) ? _hari.remove(i) : _hari.add(i);
                  _hari.sort();
                }),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _subjudul('Slot jam'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in _slotJam)
              AdminPilihChip(
                label: s.replaceAll('-', '–'),
                aktif: true,
                onHapus: () => setState(() => _slotJam.remove(s)),
              ),
            OutlinedButton.icon(
              onPressed: _tambahSlot,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah slot'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AdminColors.line),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dipakai untuk membuat jadwal baru. Jadwal yang sudah dibuat '
                    'sebelumnya tidak ikut berubah.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _seksiPerumahan() {
    return AdminSection(
      icon: Icons.account_balance_wallet_outlined,
      judul: 'Perumahan',
      children: [
        AdminFieldRow(
          icon: Icons.house_outlined,
          label: 'Booking fee rumah',
          child: _kolomAngka(_bookingFee, 'Booking fee rumah', prefix: 'Rp '),
        ),
      ],
    );
  }

  Widget _seksiRekening() {
    return AdminSection(
      icon: Icons.account_balance_outlined,
      judul: 'Rekening Pembayaran',
      children: [
        AdminFieldRow(
          icon: Icons.account_balance,
          label: 'Nama bank',
          child: _kolomTeks(_bankNama, 'Nama bank', contoh: 'BCA'),
        ),
        AdminFieldRow(
          icon: Icons.numbers,
          label: 'Nomor rekening',
          child: _kolomAngka(_bankNomor, 'Nomor rekening', bolehNol: true),
        ),
        AdminFieldRow(
          icon: Icons.badge_outlined,
          label: 'Atas nama',
          child: _kolomTeks(_bankAtasNama, 'Atas nama',
              contoh: 'RuangRancang'),
        ),
      ],
    );
  }

  // ---------- Bagian-bagian kecil ----------

  Widget _subjudul(String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(teks,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _kolomAngka(TextEditingController c, String label,
      {String? prefix, String? suffix, bool bolehNol = false}) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: adminInput(prefix: prefix, suffix: suffix),
      validator: (v) {
        if (v == null || v.isEmpty) return '$label wajib diisi';
        if (!bolehNol && (int.tryParse(v) ?? 0) <= 0) {
          return '$label harus lebih dari 0';
        }
        return null;
      },
    );
  }

  Widget _kolomTeks(TextEditingController c, String label, {String? contoh}) {
    return TextFormField(
      controller: c,
      decoration: adminInput(hint: contoh),
      validator: (v) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null,
    );
  }
}