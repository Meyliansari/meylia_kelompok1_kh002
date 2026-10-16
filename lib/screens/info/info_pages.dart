import 'package:flutter/material.dart';
import '../../config/app_info.dart';
import '../../theme/app_theme.dart';

// =====================================================================
// KERANGKA HALAMAN TEKS (dipakai S&K dan Privasi)
// =====================================================================

class _HalamanTeks extends StatelessWidget {
  final String judul;
  final String pembuka;
  final List<(String, String)> isi; // (judul bagian, isi bagian)

  const _HalamanTeks({
    required this.judul,
    required this.pembuka,
    required this.isi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(judul)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(pembuka,
              style: const TextStyle(color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 20),
          for (var i = 0; i < isi.length; i++) ...[
            Text('${i + 1}. ${isi[i].$1}', style: AppTheme.heading(17)),
            const SizedBox(height: 6),
            Text(isi[i].$2, style: const TextStyle(height: 1.55)),
            const SizedBox(height: 18),
          ],
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Dokumen ini dibuat untuk keperluan tugas kuliah. '
                'Seluruh isi bersifat fiktif.',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// SYARAT & KETENTUAN
// =====================================================================

class SyaratKetentuanPage extends StatelessWidget {
  const SyaratKetentuanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HalamanTeks(
      judul: 'Syarat & Ketentuan',
      pembuka: 'Dengan mendaftar dan menggunakan RuangRancang, kamu '
          'menyetujui ketentuan berikut.',
      isi: [
        (
        'Layanan',
        'RuangRancang menyediakan konsultasi desain rumah bersama arsitek, '
            'informasi vendor konstruksi, dan informasi perumahan dari '
            'mitra developer.'
        ),
        (
        'Akun',
        'Kamu wajib memakai email dan nomor HP milik sendiri yang aktif. '
            'Kamu bertanggung jawab menjaga kerahasiaan password. Admin '
            'berhak menonaktifkan akun yang melanggar ketentuan.'
        ),
        (
        'Pemesanan & Pembayaran',
        'Harga konsultasi mengikuti yang tertera di aplikasi saat '
            'pemesanan. Pembayaran wajib dilakukan dan buktinya diunggah '
            'sebelum batas waktu. Lewat dari batas waktu, pesanan '
            'dibatalkan otomatis dan jadwal dibuka kembali.'
        ),
        (
        'Penugasan Arsitek',
        'Arsitek ditugaskan oleh sistem berdasarkan jadwal dan '
            'ketersediaan setelah pembayaran diverifikasi admin.'
        ),
        (
        'Pembatalan & Jadwal Ulang',
        'Pembatalan atau penjadwalan ulang dapat diajukan paling lambat '
            'H-1 sebelum jadwal konsultasi.'
        ),
        (
        'Hasil Desain',
        'Hasil konsultasi boleh digunakan untuk keperluan pribadi '
            'pengguna. Penggunaan komersial memerlukan izin tertulis.'
        ),
        (
        'Perubahan Ketentuan',
        'Ketentuan ini dapat diperbarui sewaktu-waktu. Versi terbaru '
            'selalu tersedia di halaman ini.'
        ),
      ],
    );
  }
}

// =====================================================================
// KEBIJAKAN PRIVASI
// =====================================================================

class KebijakanPrivasiPage extends StatelessWidget {
  const KebijakanPrivasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HalamanTeks(
      judul: 'Kebijakan Privasi',
      pembuka: 'Kami menghargai privasimu. Berikut cara RuangRancang '
          'mengelola data pribadi.',
      isi: [
        (
        'Data yang Dikumpulkan',
        'Nama, email, nomor HP, data pemesanan konsultasi, bukti '
            'pembayaran, dan kebutuhan desain yang kamu isi.'
        ),
        (
        'Penggunaan Data',
        'Data dipakai untuk memproses pesanan, menghubungkanmu dengan '
            'arsitek atau vendor, mengirim notifikasi, dan meningkatkan '
            'layanan.'
        ),
        (
        'Penyimpanan & Keamanan',
        'Data disimpan di layanan cloud Firebase dengan akses yang '
            'dibatasi sesuai peran. Password tidak pernah dapat dilihat '
            'oleh admin.'
        ),
        (
        'Berbagi Data',
        'Data hanya dibagikan kepada arsitek yang ditugaskan atau vendor '
            'yang kamu hubungi, sebatas yang diperlukan.'
        ),
        (
        'Hak Pengguna',
        'Kamu dapat mengubah nama dan password kapan saja, serta meminta '
            'penonaktifan akun melalui Customer Service.'
        ),
      ],
    );
  }
}

// =====================================================================
// FAQ
// =====================================================================

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static const _faq = [
    (
    'Bagaimana cara memesan konsultasi?',
    'Buka menu Konsultasi Desain, pilih tanggal dan jam yang tersedia, '
        'isi kebutuhanmu, lalu lakukan pembayaran dan unggah buktinya.'
    ),
    (
    'Berapa biaya konsultasi?',
    'Biaya terbaru selalu tertera di kartu promo Beranda dan di halaman '
        'pembayaran.'
    ),
    (
    'Apakah saya bisa memilih arsitek?',
    'Tidak. Arsitek ditugaskan otomatis oleh sistem sesuai jadwal dan '
        'ketersediaan, supaya pesananmu cepat diproses.'
    ),
    (
    'Bagaimana kalau saya terlambat membayar?',
    'Pesanan dibatalkan otomatis setelah batas waktu bayar, dan kamu '
        'bisa memesan ulang.'
    ),
    (
    'Bisakah jadwal konsultasi diubah?',
    'Bisa, ajukan paling lambat H-1 melalui Customer Service.'
    ),
    (
    'Saya lupa password, bagaimana?',
    'Di halaman Masuk, isi email lalu ketuk "Lupa password?". Link untuk '
        'membuat password baru akan dikirim ke emailmu.'
    ),
    (
    'Bagaimana cara menghubungi vendor konstruksi?',
    'Buka menu Vendor Konstruksi, pilih vendor, lalu ketuk "Hubungi '
        'Vendor" dan isi kebutuhanmu.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan & FAQ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final (tanya, jawab) in _faq)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Theme(
                // hilangkan garis bawaan ExpansionTile
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.textMuted,
                  title: Text(tanya,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jawab,
                        style: const TextStyle(
                            color: AppColors.textMuted, height: 1.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
// TENTANG APLIKASI
// =====================================================================

class TentangPage extends StatelessWidget {
  const TentangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.home_outlined, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text('RuangRancang', style: AppTheme.heading(24))),
          const Center(
            child: Text('Rancang Rumah, Wujudkan Hidup · Versi 1.0.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          ),
          const SizedBox(height: 20),
          const Text(
            'RuangRancang adalah aplikasi konsultasi desain rumah yang '
                'menghubungkan pengguna dengan arsitek profesional, vendor '
                'konstruksi, dan perumahan pilihan dalam satu aplikasi.',
            style: TextStyle(height: 1.55),
          ),
          const SizedBox(height: 24),
          Text('Tim Pengembang', style: AppTheme.heading(18)),
          const SizedBox(height: 8),
          for (final a in AppInfo.tim)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(a.nama[0],
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
              title: Text(a.nama,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(a.peran),
            ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© ${AppInfo.tahun} RuangRancang · ${AppInfo.namaKelompok}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}