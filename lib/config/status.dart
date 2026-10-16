/// KESEPAKATAN KELOMPOK: nama koleksi & nilai status.
/// Semua anggota WAJIB memakai konstanta ini, jangan ketik teks manual,
/// supaya tidak ada salah huruf dan Dashboard Admin bisa membacanya.

class Koleksi {
  Koleksi._();
  static const users = 'users';
  static const arsitek = 'arsitek';
  static const pengaturan = 'pengaturan';
  static const konsultasi = 'konsultasi';
  static const jadwal = 'jadwal';
  static const perumahan = 'perumahan';
  static const pesananRumah = 'pesanan_rumah';
  static const vendor = 'vendor';
  static const permintaanVendor = 'permintaan_vendor';
  static const notifikasi = 'notifikasi';
  static const portofolio = 'portofolio';
}

/// Koleksi `konsultasi`. Field wajib untuk Dashboard Admin:
/// userNama, tanggal ("2026-10-05"), jam, harga, status, createdAt
class StatusKonsultasi {
  StatusKonsultasi._();
  static const menungguPembayaran = 'menunggu_pembayaran';
  static const menungguVerifikasi = 'menunggu_verifikasi';
  static const dikonfirmasi = 'dikonfirmasi';
  static const selesai = 'selesai';
  static const ditolak = 'ditolak';
  static const dibatalkan = 'dibatalkan';
}

/// Koleksi `pesanan_rumah`. Field wajib:
/// userNama, perumahanNama, bookingFee, status, createdAt
class StatusPesananRumah {
  StatusPesananRumah._();
  static const menungguPembayaran = 'menunggu_pembayaran';
  static const menungguVerifikasi = 'menunggu_verifikasi';
  static const disetujui = 'disetujui';
  static const ditolak = 'ditolak';
  static const dibatalkan = 'dibatalkan';
}

/// Koleksi `permintaan_vendor`. Field wajib:
/// userNama, jenisPekerjaan, status, createdAt
class StatusPermintaanVendor {
  StatusPermintaanVendor._();
  static const baru = 'baru';
  static const diteruskan = 'diteruskan';
  static const dihubungi = 'dihubungi';
  static const selesai = 'selesai';
}


/// Peran akun di field `role` koleksi `users`
class Role {
  Role._();
  static const user = 'user';
  static const arsitek = 'arsitek';
  static const admin = 'admin';
  static const semua = [user, arsitek, admin];
}