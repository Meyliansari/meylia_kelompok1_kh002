/// Isi dokumen Firestore `pengaturan/aplikasi`: semua angka & aturan
/// yang diatur admin dan dibaca oleh seluruh aplikasi.
class Pengaturan {
  final int hargaKonsultasi; // rupiah
  final String durasiKonsultasi; // contoh: "2 jam"
  final int batasBayarJam; // batas waktu upload bukti bayar
  final int bookingFeeRumah; // rupiah
  final String bankNama;
  final String bankNomor;
  final String bankAtasNama;
  final List<String> slotJam; // contoh: ["09:00-11:00", ...]
  final List<int> hariOperasional; // 1 = Senin ... 7 = Minggu

  const Pengaturan({
    required this.hargaKonsultasi,
    required this.durasiKonsultasi,
    required this.batasBayarJam,
    required this.bookingFeeRumah,
    required this.bankNama,
    required this.bankNomor,
    required this.bankAtasNama,
    required this.slotJam,
    required this.hariOperasional,
  });

  /// Nilai bawaan: dipakai kalau dokumen belum ada atau ada field yang kosong,
  /// supaya aplikasi tetap jalan.
  static const bawaan = Pengaturan(
    hargaKonsultasi: 150000,
    durasiKonsultasi: '2 jam',
    batasBayarJam: 24,
    bookingFeeRumah: 10000000,
    bankNama: 'BCA',
    bankNomor: '1234567890',
    bankAtasNama: 'RuangRancang',
    slotJam: ['09:00-11:00', '11:00-13:00', '13:00-15:00', '15:00-17:00'],
    hariOperasional: [1, 2, 3, 4, 5, 6],
  );

  /// Firestore → objek Dart. Field yang tidak ada diisi nilai bawaan.
  factory Pengaturan.fromMap(Map<String, dynamic>? m) {
    if (m == null) return bawaan;
    final b = bawaan;
    return Pengaturan(
      hargaKonsultasi: (m['hargaKonsultasi'] as num?)?.toInt() ?? b.hargaKonsultasi,
      durasiKonsultasi: m['durasiKonsultasi'] as String? ?? b.durasiKonsultasi,
      batasBayarJam: (m['batasBayarJam'] as num?)?.toInt() ?? b.batasBayarJam,
      bookingFeeRumah: (m['bookingFeeRumah'] as num?)?.toInt() ?? b.bookingFeeRumah,
      bankNama: m['bankNama'] as String? ?? b.bankNama,
      bankNomor: m['bankNomor'] as String? ?? b.bankNomor,
      bankAtasNama: m['bankAtasNama'] as String? ?? b.bankAtasNama,
      slotJam: (m['slotJam'] as List?)?.map((e) => e.toString()).toList() ??
          b.slotJam,
      hariOperasional: (m['hariOperasional'] as List?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
          b.hariOperasional,
    );
  }

  /// Objek Dart → Firestore (dipakai halaman Pengaturan admin di 5B)
  Map<String, dynamic> toMap() => {
    'hargaKonsultasi': hargaKonsultasi,
    'durasiKonsultasi': durasiKonsultasi,
    'batasBayarJam': batasBayarJam,
    'bookingFeeRumah': bookingFeeRumah,
    'bankNama': bankNama,
    'bankNomor': bankNomor,
    'bankAtasNama': bankAtasNama,
    'slotJam': slotJam,
    'hariOperasional': hariOperasional,
  };
}