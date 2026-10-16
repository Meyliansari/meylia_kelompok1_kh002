import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';

/// Satu akun dari koleksi `users`.
class Pengguna {
  final String uid;
  final String nama;
  final String email;
  final String noHp; // tanpa +62
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const Pengguna({
    required this.uid,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  /// Dokumen Firestore → objek Dart. Field kosong diisi nilai aman.
  factory Pengguna.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final dibuat = m['createdAt'];
    return Pengguna(
      uid: doc.id,
      nama: (m['nama'] as String?)?.trim().isNotEmpty == true
          ? m['nama'] as String
          : '(tanpa nama)',
      email: m['email'] as String? ?? '-',
      noHp: m['noHp'] as String? ?? '',
      role: m['role'] as String? ?? Role.user,
      isActive: m['isActive'] != false, // kosong dianggap aktif
      createdAt: dibuat is Timestamp ? dibuat.toDate() : null,
    );
  }

  /// Huruf depan nama untuk foto profil
  String get inisial => nama.isNotEmpty ? nama[0].toUpperCase() : '?';
}