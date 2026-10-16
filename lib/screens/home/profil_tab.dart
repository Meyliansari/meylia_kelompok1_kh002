import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_info.dart';
import '../../config/status.dart';
import '../../models/pengguna.dart';
import '../../services/auth_service.dart';
import '../../services/profil_service.dart';
import '../../theme/app_theme.dart';
import '../auth/after_login.dart';
import '../info/info_pages.dart';

/// Tab Profil. Dipakai oleh USER dan ARSITEK.
/// modeArsitek = true → bagian "Aktivitas Saya" disembunyikan.
class ProfilTab extends StatefulWidget {
  final bool modeArsitek;

  const ProfilTab({super.key, this.modeArsitek = false});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  late final Stream<Pengguna?> _stream;

  @override
  void initState() {
    super.initState();
    _stream = ProfilService.streamSaya();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  void _buka(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<Pengguna?>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text('Profil', style: AppTheme.heading(26)),
              const SizedBox(height: 16),
              _kartuIdentitas(p),
              const SizedBox(height: 22),

              _grup('Akun', [
                _item(Icons.person_outline, 'Ubah nama',
                        () => _dialogNama(p)),
                _item(Icons.lock_outline, 'Ubah password', _dialogPassword),
              ]),

              if (!widget.modeArsitek)
                _grup('Aktivitas Saya', [
                  _item(Icons.design_services_outlined, 'Konsultasi Saya',
                          () => _pesan('Riwayat konsultasi segera hadir (Anggota 2)')),
                  _item(Icons.house_outlined, 'Pesanan Rumah',
                          () => _pesan('Pesanan rumah segera hadir (Anggota 4)')),
                  _item(Icons.engineering_outlined, 'Permintaan Vendor',
                          () => _pesan('Permintaan vendor segera hadir (Anggota 5)')),
                ]),

              _grup('Bantuan & Info', [
                _item(Icons.help_outline, 'Bantuan & FAQ',
                        () => _buka(const FaqPage())),
                _item(Icons.chat_outlined, 'Hubungi CS (WhatsApp)', _hubungiCs),
                _item(Icons.description_outlined, 'Syarat & Ketentuan',
                        () => _buka(const SyaratKetentuanPage())),
                _item(Icons.shield_outlined, 'Kebijakan Privasi',
                        () => _buka(const KebijakanPrivasiPage())),
                _item(Icons.info_outline, 'Tentang Aplikasi',
                        () => _buka(const TentangPage())),
              ]),

              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _konfirmasiKeluar,
                icon: Icon(Icons.logout, color: Colors.red.shade700),
                label: Text('Keluar',
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text('RuangRancang v1.0.0',
                    style:
                    TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===================== TAMPILAN =====================

  /// Kartu atas: foto (inisial), nama, nomor HP, email, peran
  Widget _kartuIdentitas(Pengguna? p) {
    final labelPeran = p?.role == Role.arsitek ? 'Arsitek' : 'Pengguna';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary,
            child: Text(p?.inisial ?? '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p?.nama ?? '-', style: AppTheme.heading(20)),
                if ((p?.noHp ?? '').isNotEmpty)
                  Text('+62${p!.noHp}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12.5)),
                Text(p?.email ?? '-',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12.5)),
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(labelPeran,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Satu kelompok menu dengan judul kecil di atasnya
  Widget _grup(String judul, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(judul.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1, indent: 60, color: AppColors.border),
                  items[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Satu baris menu: ikon bulat, tulisan, panah
  Widget _item(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }

  // ===================== AKSI =====================

  Future<void> _dialogNama(Pengguna? p) async {
    final c = TextEditingController(text: p?.nama ?? '');
    final formKey = GlobalKey<FormState>();

    final namaBaru = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Ubah nama', style: AppTheme.heading(18)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: c,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Nama lengkap'),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'Nama minimal 3 huruf'
                : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, c.text.trim());
              }
            },
            child: const Text('Simpan',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    c.dispose();

    if (namaBaru == null || namaBaru == p?.nama) return;
    try {
      await ProfilService.ubahNama(namaBaru);
      _pesan('Nama berhasil diubah.');
    } catch (e) {
      _pesan(AuthService.errorMessage(e));
    }
  }

  Future<void> _dialogPassword() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _DialogPassword(),
    );
  }

  Future<void> _hubungiCs() async {
    final uri = Uri.https('wa.me', '/${AppInfo.whatsapp}', {
      'text': 'Halo CS RuangRancang, saya butuh bantuan.',
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _pesan('Tidak bisa membuka WhatsApp.');
  }

  Future<void> _konfirmasiKeluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Keluar dari akun?', style: AppTheme.heading(18)),
        content: const Text('Kamu perlu masuk lagi untuk memakai aplikasi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar',
                style: TextStyle(
                    color: Colors.red.shade700, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (yakin == true && mounted) await logoutAndGoToLogin(context);
  }
}

// =====================================================================
// DIALOG UBAH PASSWORD (punya state sendiri: loading & pesan error)
// =====================================================================

class _DialogPassword extends StatefulWidget {
  const _DialogPassword();

  @override
  State<_DialogPassword> createState() => _DialogPasswordState();
}

class _DialogPasswordState extends State<_DialogPassword> {
  final _formKey = GlobalKey<FormState>();
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _ulang = TextEditingController();
  bool _sembunyi = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _ulang.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ProfilService.ubahPassword(_lama.text, _baru.text);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah.')));
    } on FirebaseAuthException catch (e) {
      final pesan = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Password lama salah.',
        'no-email' => 'Akun ini tidak memakai password.',
        _ => AuthService.errorMessage(e),
      };
      if (mounted) setState(() => _error = pesan);
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dekor(String label) => InputDecoration(
    labelText: label,
    suffixIcon: IconButton(
      icon: Icon(_sembunyi
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined),
      onPressed: () => setState(() => _sembunyi = !_sembunyi),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Ubah password', style: AppTheme.heading(18)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _lama,
                obscureText: _sembunyi,
                decoration: _dekor('Password lama'),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _baru,
                obscureText: _sembunyi,
                decoration: _dekor('Password baru'),
                validator: (v) {
                  final t = v ?? '';
                  if (t.length < 8) return 'Minimal 8 karakter';
                  if (!RegExp(r'[0-9]').hasMatch(t)) {
                    return 'Harus mengandung angka';
                  }
                  if (t == _lama.text) return 'Harus beda dari password lama';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ulang,
                obscureText: _sembunyi,
                decoration: _dekor('Ulangi password baru'),
                validator: (v) =>
                v != _baru.text ? 'Password tidak sama' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _loading ? null : _simpan,
          child: _loading
              ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}