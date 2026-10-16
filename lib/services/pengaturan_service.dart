import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pengaturan.dart';

/// Satu-satunya pintu untuk membaca & mengubah pengaturan aplikasi.
/// Dipakai SEMUA anggota (jangan baca dokumen pengaturan langsung).
class PengaturanService {
  static final _doc =
  FirebaseFirestore.instance.collection('pengaturan').doc('aplikasi');

  /// Berlangganan pengaturan: setiap admin mengubahnya, nilai baru dikirim
  /// otomatis. Kalau gagal dibaca, pakai nilai bawaan.
  static Stream<Pengaturan> stream() => _doc
      .snapshots()
      .map((snap) => Pengaturan.fromMap(snap.data()))
      .handleError((_) => Pengaturan.bawaan);

  /// Ambil sekali (untuk proses yang tidak perlu live, misal saat booking)
  static Future<Pengaturan> ambil() async {
    try {
      final snap = await _doc.get();
      return Pengaturan.fromMap(snap.data());
    } catch (_) {
      return Pengaturan.bawaan;
    }
  }

  /// Simpan pengaturan (hanya admin, dijaga oleh Security Rules)
  static Future<void> simpan(Pengaturan p) =>
      _doc.set(p.toMap(), SetOptions(merge: true));
}