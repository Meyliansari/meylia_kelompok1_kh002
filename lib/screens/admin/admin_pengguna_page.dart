import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../models/pengguna.dart';
import '../../services/auth_service.dart';
import '../../services/pengguna_service.dart';
import '../../theme/app_theme.dart';
import 'admin_ringkasan.dart'; // AdminColors
import 'admin_widgets.dart';

/// Halaman admin: daftar akun, cari, saring, ubah status & peran.
class AdminPenggunaPage extends StatefulWidget {
  const AdminPenggunaPage({super.key});

  @override
  State<AdminPenggunaPage> createState() => _AdminPenggunaPageState();
}

class _AdminPenggunaPageState extends State<AdminPenggunaPage> {
  static const _filterList = ['semua', Role.user, Role.arsitek, Role.admin];

  final _cari = TextEditingController();
  final _uidSaya = FirebaseAuth.instance.currentUser?.uid;
  late final Stream<List<Pengguna>> _stream;
  String _filter = 'semua';

  @override
  void initState() {
    super.initState();
    _stream = PenggunaService.stream();
    _cari.addListener(() => setState(() {})); // saring ulang saat mengetik
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  // ===================== BANTUAN =====================

  String _labelRole(String r) => switch (r) {
    'semua' => 'Semua',
    Role.arsitek => 'Arsitek',
    Role.admin => 'Admin',
    _ => 'User',
  };

  int _hitung(List<Pengguna> semua, String f) =>
      f == 'semua' ? semua.length : semua.where((p) => p.role == f).length;

  /// Saring berdasarkan peran + kata pencarian
  List<Pengguna> _saring(List<Pengguna> semua) {
    final q = _cari.text.trim().toLowerCase();
    return semua.where((p) {
      final cocokRole = _filter == 'semua' || p.role == _filter;
      final cocokCari = q.isEmpty ||
          p.nama.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.noHp.contains(q);
      return cocokRole && cocokCari;
    }).toList();
  }

  String _tanggal(DateTime? d) {
    if (d == null) return '-';
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  /// Dialog "Yakin?" → true kalau admin menekan tombol konfirmasi
  Future<bool> _konfirmasi(String judul, String isi, String teksYa) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(judul, style: AppTheme.heading(18)),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(teksYa,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  // ===================== AKSI =====================

  Future<void> _ubahRole(Pengguna p, String roleBaru) async {
    final label = _labelRole(roleBaru);
    var isi = switch (roleBaru) {
      Role.arsitek =>
      'Profil arsitek akan dibuat otomatis, dan akun ini bisa menerima '
          'tugas konsultasi. Spesialisasi dilengkapi di menu Arsitek & Jadwal.',
      Role.admin =>
      'Akun ini akan punya akses penuh ke Dashboard Admin. '
          'Pastikan orangnya tepercaya.',
      _ => 'Akun ini kembali menjadi pengguna biasa.',
    };
    if (p.role == Role.arsitek && roleBaru != Role.arsitek) {
      isi += ' Profil arsiteknya dinonaktifkan sehingga tidak menerima tugas baru.';
    }

    final ok = await _konfirmasi('Jadikan ${p.nama} $label?', isi, 'Ubah');
    if (!ok) return;

    try {
      await PenggunaService.ubahRole(p, roleBaru);
      _pesan('Peran ${p.nama} sekarang $label. Berlaku saat ia login ulang.');
    } catch (e) {
      _pesan(AuthService.errorMessage(e));
    }
  }

  Future<void> _ubahAktif(Pengguna p, bool aktif) async {
    if (!aktif) {
      final ok = await _konfirmasi(
        'Nonaktifkan ${p.nama}?',
        'Akun ini tidak bisa login sampai diaktifkan kembali. '
            'Data dan riwayatnya tetap aman.',
        'Nonaktifkan',
      );
      if (!ok) return;
    }

    try {
      await PenggunaService.setAktif(p, aktif);
      _pesan(aktif
          ? '${p.nama} diaktifkan kembali.'
          : '${p.nama} dinonaktifkan.');
    } catch (e) {
      _pesan(AuthService.errorMessage(e));
    }
  }

  // ===================== TAMPILAN =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Pengguna>>(
          stream: _stream,
          builder: (context, snap) {
            final semua = snap.data ?? [];
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const AdminPageHeader(
                  icon: Icons.group_rounded,
                  judul: 'Kelola Pengguna',
                  subjudul: 'Atur status akun dan peran pengguna.',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminSection(
                        icon: Icons.manage_search,
                        judul: 'Cari & Saring',
                        children: [
                          TextField(
                            controller: _cari,
                            decoration: adminInput(
                                hint: 'Cari nama, email, atau nomor HP')
                                .copyWith(
                                prefixIcon: const Icon(Icons.search)),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final f in _filterList)
                                AdminPilihChip(
                                  label:
                                  '${_labelRole(f)} (${_hitung(semua, f)})',
                                  aktif: _filter == f,
                                  onTap: () => setState(() => _filter = f),
                                ),
                            ],
                          ),
                        ],
                      ),
                      AdminSection(
                        icon: Icons.people_outline,
                        judul: 'Daftar Pengguna',
                        children: [_isiDaftar(snap)],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _isiDaftar(AsyncSnapshot<List<Pengguna>> snap) {
    if (snap.hasError) {
      return Text('Gagal memuat: ${AuthService.errorMessage(snap.error!)}',
          style: const TextStyle(color: Colors.red));
    }
    if (!snap.hasData) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final list = _saring(snap.data!);
    if (list.isEmpty) {
      return const Text('Tidak ada pengguna yang cocok.',
          style: TextStyle(color: AppColors.textMuted));
    }
    return Column(children: [for (final p in list) _kartu(p)]);
  }

  /// Satu baris akun di daftar
  Widget _kartu(Pengguna p) {
    final diriSendiri = p.uid == _uidSaya;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _bukaDetail(p),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.line),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                  p.isActive ? AdminUi.iconBg : Colors.grey.shade200,
                  child: Text(p.inisial,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: p.isActive
                              ? AppColors.primary
                              : AppColors.textMuted)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.nama,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                          if (diriSendiri)
                            const Text(' (kamu)',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                      Text(p.email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      if (!p.isActive)
                        Text('Nonaktif',
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _badgeRole(p.role),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Label peran berwarna: Admin (army), Arsitek (sage), User (pucat)
  Widget _badgeRole(String role) {
    final (bg, fg) = switch (role) {
      Role.admin => (AdminUi.army, Colors.white),
      Role.arsitek => (AdminColors.soft, AppColors.primary),
      _ => (AdminUi.strip, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_labelRole(role),
          style: TextStyle(
              color: fg, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }

  /// Lembar detail dari bawah layar: info akun + ubah peran & status
  void _bukaDetail(Pengguna p) {
    final diriSendiri = p.uid == _uidSaya;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis kecil penanda bisa ditarik
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AdminUi.iconBg,
                    child: Text(p.inisial,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nama, style: AppTheme.heading(20)),
                        Text(p.email,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _infoBaris(Icons.phone_outlined,
                  p.noHp.isEmpty ? '-' : '+62${p.noHp}'),
              _infoBaris(Icons.calendar_today_outlined,
                  'Terdaftar ${_tanggal(p.createdAt)}'),
              const SizedBox(height: 16),

              if (diriSendiri)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminUi.strip,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Ini akun kamu sendiri. Peran dan status tidak bisa '
                        'diubah dari sini, supaya admin tidak mengunci dirinya '
                        'sendiri.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),

              const Text('Peran',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in Role.semua)
                    AdminPilihChip(
                      label: _labelRole(r),
                      aktif: p.role == r,
                      onTap: (diriSendiri || p.role == r)
                          ? null
                          : () {
                        Navigator.pop(ctx);
                        _ubahRole(p, r);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),

              const Text('Status akun',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.isActive
                          ? 'Aktif, bisa login'
                          : 'Nonaktif, tidak bisa login',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  Switch(
                    value: p.isActive,
                    activeTrackColor: AdminUi.army,
                    onChanged: diriSendiri
                        ? null
                        : (v) {
                      Navigator.pop(ctx);
                      _ubahAktif(p, v);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBaris(IconData icon, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(teks, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}