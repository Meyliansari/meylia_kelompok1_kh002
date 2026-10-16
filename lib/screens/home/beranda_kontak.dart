import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_info.dart';
import '../../theme/app_theme.dart';

/// Membuka link di aplikasi lain (WhatsApp, telepon, email, browser).
/// Kalau gagal (misal aplikasinya tidak ada), tampilkan pesan.
Future<void> _bukaLink(BuildContext context, Uri uri) async {
  final berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!berhasil && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak bisa membuka aplikasi tujuan.')),
    );
  }
}

// =====================================================================
// KONTAK DARURAT
// =====================================================================

class KontakDarurat extends StatelessWidget {
  const KontakDarurat({super.key});

  @override
  Widget build(BuildContext context) {
    final whatsapp = Uri.https('wa.me', '/${AppInfo.whatsapp}', {
      'text': 'Halo RuangRancang, saya butuh bantuan.',
    });
    final telepon = Uri(scheme: 'tel', path: AppInfo.telepon);
    final email = Uri(
      scheme: 'mailto',
      path: AppInfo.email,
      query: 'subject=Bantuan%20RuangRancang',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Butuh Bantuan?', style: AppTheme.heading(18)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tim kami siap membantu: ${AppInfo.jamOperasional}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _kontakItem(
              context,
              icon: Icons.chat_outlined,
              judul: 'WhatsApp',
              isi: '+${AppInfo.whatsapp}',
              uri: whatsapp,
            ),
            _kontakItem(
              context,
              icon: Icons.call_outlined,
              judul: 'Telepon',
              isi: AppInfo.telepon,
              uri: telepon,
            ),
            _kontakItem(
              context,
              icon: Icons.mail_outline,
              judul: 'Email',
              isi: AppInfo.email,
              uri: email,
            ),
          ],
        ),
      ),
    );
  }

  Widget _kontakItem(
      BuildContext context, {
        required IconData icon,
        required String judul,
        required String isi,
        required Uri uri,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _bukaLink(context, uri),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(isi,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// FOOTER: identitas, alamat, media sosial, tim pengembang, watermark
// =====================================================================

class BerandaFooter extends StatelessWidget {
  const BerandaFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + tagline
          Row(
            children: [
              const Icon(Icons.home_outlined, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Text('RuangRancang',
                  style: AppTheme.heading(20).copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Rancang Rumah, Wujudkan Hidup',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Alamat
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppInfo.alamat,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Media sosial
          const Text(
            'Ikuti Kami',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _sosmed(context, Icons.camera_alt_outlined, 'Instagram',
                  AppInfo.instagram),
              _sosmed(context, Icons.music_note_outlined, 'TikTok',
                  AppInfo.tiktok),
              _sosmed(context, Icons.play_circle_outline, 'YouTube',
                  AppInfo.youtube),
            ],
          ),

          // Tim pengembang
          const SizedBox(height: 24),
          const Text(
            'Tim Pengembang',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildTim(),

          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Watermark
          const Center(
            child: Column(
              children: [
                Text(
                  '© ${AppInfo.tahun} RuangRancang · Dibuat oleh ${AppInfo.namaKelompok}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                SizedBox(height: 4),
                Text(
                  'Proyek tugas kuliah. Data dan kontak bersifat fiktif.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Satu tombol media sosial berbentuk "pil" dengan ikon + nama.
  Widget _sosmed(
      BuildContext context, IconData icon, String nama, String url) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _bukaLink(context, Uri.parse(url)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(nama,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  /// Foto kelompok + daftar anggota dalam satu kolom.
  Widget _buildTim() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Satu foto kelompok, lebar penuh
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            AppInfo.fotoTim,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            // Foto belum ada → kotak dengan ikon grup
            errorBuilder: (_, __, ___) => Container(
              height: 180,
              color: Colors.white12,
              alignment: Alignment.center,
              child: const Icon(Icons.groups_outlined,
                  color: Colors.white54, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Daftar anggota, satu per baris
        for (var i = 0; i < AppInfo.tim.length; i++)
          _anggotaRow(i + 1, AppInfo.tim[i]),
      ],
    );
  }

  /// Satu baris anggota: nomor bulat, nama + NIM, peran.
  Widget _anggotaRow(int nomor, AnggotaTim a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white24,
            child: Text(
              '$nomor',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.nim.isEmpty ? a.nama : '${a.nama} · ${a.nim}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  a.peran,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}