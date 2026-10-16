import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';
import '../models/pengguna.dart';

/// Urusan mengelola akun pengguna (khusus admin; dijaga Security Rules).
class PenggunaService {
  static final _db = FirebaseFirestore.instance;

  /// Semua akun, terbaru di atas. Update otomatis (live).
  static Stream<List<Pengguna>> stream() {
    return _db.collection(Koleksi.users).snapshots().map((snap) {
      final list = snap.docs.map(Pengguna.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(2000))
          .compareTo(a.createdAt ?? DateTime(2000)));
      return list;
    });
  }

  /// Aktifkan / nonaktifkan akun.
  /// Kalau dia arsitek, profil arsiteknya ikut diaktif/nonaktifkan.
  static Future<void> setAktif(Pengguna p, bool aktif) async {
    final batch = _db.batch();
    batch.update(_db.collection(Koleksi.users).doc(p.uid), {
      'isActive': aktif,
      'diperbaruiPada': FieldValue.serverTimestamp(),
    });
    if (p.role == Role.arsitek) {
      batch.set(
        _db.collection(Koleksi.arsitek).doc(p.uid),
        {'isActive': aktif},
        SetOptions(merge: true),
      );
    }
    await batch.commit(); // semua berhasil, atau tidak ada yang berubah
  }

  /// Ubah peran akun.
  /// - Jadi arsitek → profil `arsitek/{uid}` dibuat (atau diaktifkan lagi)
  /// - Turun dari arsitek → profil arsitek dinonaktifkan (tidak dihapus)
  static Future<void> ubahRole(Pengguna p, String roleBaru) async {
    final userRef = _db.collection(Koleksi.users).doc(p.uid);
    final arsitekRef = _db.collection(Koleksi.arsitek).doc(p.uid);
    final profilArsitek = await arsitekRef.get();

    final batch = _db.batch();
    batch.update(userRef, {
      'role': roleBaru,
      'diperbaruiPada': FieldValue.serverTimestamp(),
    });

    if (roleBaru == Role.arsitek) {
      if (profilArsitek.exists) {
        batch.update(arsitekRef, {'isActive': true, 'nama': p.nama});
      } else {
        batch.set(arsitekRef, {
          'nama': p.nama,
          'spesialisasi': 'Belum diisi',
          'pengalaman': 0,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else if (p.role == Role.arsitek && profilArsitek.exists) {
      batch.update(arsitekRef, {'isActive': false});
    }

    await batch.commit();
  }
}