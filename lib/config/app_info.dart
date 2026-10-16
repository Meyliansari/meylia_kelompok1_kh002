/// Data satu anggota tim (dipakai di footer Beranda).
class AnggotaTim {
  final String nama;
  final String nim;
  final String peran;

  const AnggotaTim({
    required this.nama,
    required this.nim,
    required this.peran,
  });
}

/// Semua info kontak & identitas aplikasi dikumpulkan di sini.
/// Ganti isinya kapan saja, tampilan Beranda otomatis ikut berubah.
class AppInfo {
  AppInfo._(); // tidak perlu dibuat objeknya, cukup AppInfo.namaField

  // ---------- Kontak darurat (CONTOH FIKTIF, ganti nanti) ----------
  static const String whatsapp = '6281200001111'; // format 62xxx, tanpa + dan 0
  static const String telepon = '0221234567';
  static const String email = 'halo@ruangrancang.id';
  static const String jamOperasional = 'Senin–Sabtu, 08.00–20.00 WIB';

  // ---------- Kantor ----------
  static const String alamat =
      'Jl. Contoh Arsitektur No. 12, Bandung, Jawa Barat';

  // ---------- Tim pengembang ----------
  static const String fotoTim = 'lib/images/fotoanggota.jpg'; // 1 foto kelompok

  static const List<AnggotaTim> tim = [
    AnggotaTim(
      nama: 'Deswinta Dwi Putri',
      nim: '20240801222',
      peran: 'Fondasi & Beranda',
    ),
    AnggotaTim(
      nama: 'Nama Anggota 2',
      nim: '20240801223',
      peran: 'Konsultasi (User)',
    ),
    AnggotaTim(
      nama: 'Nama Anggota 3',
      nim: '20240801224',
      peran: 'Admin & Arsitek',
    ),
    AnggotaTim(
      nama: 'Nama Anggota 4',
      nim: '20240801225',
      peran: 'Perumahan',
    ),
    AnggotaTim(
      nama: 'Nama Anggota 5',
      nim: '20240801226',
      peran: 'Vendor & Notifikasi',
    ),
  ];

  // ---------- Media sosial (CONTOH FIKTIF) ----------
  static const String instagram = 'https://instagram.com/ruangrancang.id';
  static const String tiktok = 'https://tiktok.com/@ruangrancang.id';
  static const String youtube = 'https://youtube.com/@ruangrancang';

  // ---------- Watermark ----------
  static const String namaKelompok = 'Kelompok X'; // ganti nama kelompokmu
  static const int tahun = 2026;
}