import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu proyek di koleksi `portofolio` (tampil di "Proyek Terbaru" Beranda).
class Proyek {
  final String id; // kosong = proyek baru (belum tersimpan)
  final String nama;
  final String kota;
  final String gambar; // path aset (lib/images/...) ATAU link http
  final bool tampil; // false = disembunyikan dari Beranda
  final int urutan; // kecil = tampil lebih dulu
  final DateTime? createdAt;

  const Proyek({
    this.id = '',
    required this.nama,
    required this.kota,
    required this.gambar,
    this.tampil = true,
    this.urutan = 0,
    this.createdAt,
  });

  factory Proyek.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final dibuat = m['createdAt'];
    return Proyek(
      id: doc.id,
      nama: m['nama'] as String? ?? '',
      kota: m['kota'] as String? ?? '',
      gambar: m['gambar'] as String? ?? '',
      tampil: m['tampil'] != false,
      urutan: (m['urutan'] as num?)?.toInt() ?? 0,
      createdAt: dibuat is Timestamp ? dibuat.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'nama': nama,
    'kota': kota,
    'gambar': gambar,
    'tampil': tampil,
    'urutan': urutan,
  };
}