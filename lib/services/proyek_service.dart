import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';
import '../models/proyek.dart';

/// Baca & kelola proyek di koleksi `portofolio`.
class ProyekService {
  static final _col =
  FirebaseFirestore.instance.collection(Koleksi.portofolio);

  /// Urutkan: `urutan` kecil dulu, lalu yang terbaru
  static List<Proyek> _urutkan(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map(Proyek.fromDoc).toList();
    list.sort((a, b) {
      final u = a.urutan.compareTo(b.urutan);
      if (u != 0) return u;
      return (b.createdAt ?? DateTime(2000))
          .compareTo(a.createdAt ?? DateTime(2000));
    });
    return list;
  }

  /// Semua proyek (untuk admin)
  static Stream<List<Proyek>> streamSemua() =>
      _col.snapshots().map(_urutkan);

  /// Hanya proyek yang ditampilkan (untuk Beranda user)
  static Stream<List<Proyek>> streamTampil() =>
      _col.where('tampil', isEqualTo: true).snapshots().map(_urutkan);

  /// Tambah (kalau id kosong) atau ubah (kalau id ada)
  static Future<void> simpan(Proyek p) async {
    if (p.id.isEmpty) {
      await _col.add({...p.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await _col.doc(p.id).update(
          {...p.toMap(), 'diperbaruiPada': FieldValue.serverTimestamp()});
    }
  }

  static Future<void> setTampil(String id, bool tampil) =>
      _col.doc(id).update({'tampil': tampil});

  static Future<void> hapus(String id) => _col.doc(id).delete();

  /// Isi 3 proyek contoh (dipakai sekali saat koleksi masih kosong)
  static Future<void> isiContoh() async {
    final batch = FirebaseFirestore.instance.batch();
    const contoh = [
      Proyek(
          nama: 'Rumah Tropis Kayu',
          kota: 'Ubud, Bali',
          gambar: 'lib/images/dashboardperumahan1.jpg',
          urutan: 1),
      Proyek(
          nama: 'Rumah Modern Minimalis',
          kota: 'Bandung',
          gambar: 'lib/images/dashboardperumahan2.jpg',
          urutan: 2),
      Proyek(
          nama: 'Asri Green Residence',
          kota: 'Bogor',
          gambar: 'lib/images/dashboardperumahan3.jpg',
          urutan: 3),
    ];
    for (final p in contoh) {
      batch.set(_col.doc(),
          {...p.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }
}