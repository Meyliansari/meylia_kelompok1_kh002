import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// Warna army lembut khusus halaman admin
class AdminColors {
  AdminColors._();
  static const soft = Color(0xFFC9D6BA); // kartu aktif
  static const pale = Color(0xFFDDE5D2); // kartu "segera hadir"
  static const line = Color(0xFFADBD9C); // garis tepi
}

/// Tanggal format "2026-10-03" (sama dengan field `tanggal` konsultasi)
String tanggalIso(DateTime d) => '${d.year}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

// =====================================================================
// JAM REAL TIME
// =====================================================================

/// Jam yang berjalan setiap detik, contoh: "14:32:05 WIB"
class JamLive extends StatefulWidget {
  const JamLive({super.key});

  @override
  State<JamLive> createState() => _JamLiveState();
}

class _JamLiveState extends State<JamLive> {
  late final Timer _timer;
  DateTime _sekarang = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sekarang = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // wajib, supaya timer berhenti saat halaman ditutup
    super.dispose();
  }

  String _dua(int n) => n.toString().padLeft(2, '0'); // 7 → "07"

  @override
  Widget build(BuildContext context) {
    final j = _sekarang;
    return Text(
      '${_dua(j.hour)}:${_dua(j.minute)}:${_dua(j.second)} WIB',
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()], // angka tidak "goyang"
      ),
    );
  }
}

// =====================================================================
// RINGKASAN HARI INI: angka live dari Firestore
// =====================================================================

class RingkasanAdmin extends StatefulWidget {
  final bool denganJudul;

  const RingkasanAdmin({super.key, this.denganJudul = true});

  @override
  State<RingkasanAdmin> createState() => _RingkasanAdminState();
}

class _RingkasanAdminState extends State<RingkasanAdmin> {
  // Stream dibuat SEKALI di initState, supaya tidak berlangganan ulang
  // setiap kali layar digambar ulang.
  late final Stream<int> _menunggu;
  late final Stream<int> _hariIni;
  late final Stream<int> _booking;
  late final Stream<int> _vendor;
  late final Stream<int> _pendapatan;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    final konsul = db.collection(Koleksi.konsultasi);

    _menunggu = konsul
        .where('status', isEqualTo: StatusKonsultasi.menungguVerifikasi)
        .snapshots()
        .map((s) => s.docs.length);

    // Konsultasi hari ini yang sudah dikonfirmasi / selesai
    _hariIni = konsul
        .where('tanggal', isEqualTo: tanggalIso(DateTime.now()))
        .snapshots()
        .map((s) => s.docs.where((d) {
      final st = d.data()['status'];
      return st == StatusKonsultasi.dikonfirmasi ||
          st == StatusKonsultasi.selesai;
    }).length);

    _booking = db
        .collection(Koleksi.pesananRumah)
        .where('status', isEqualTo: StatusPesananRumah.menungguVerifikasi)
        .snapshots()
        .map((s) => s.docs.length);

    _vendor = db
        .collection(Koleksi.permintaanVendor)
        .where('status', isEqualTo: StatusPermintaanVendor.baru)
        .snapshots()
        .map((s) => s.docs.length);

    // Jumlah harga konsultasi (dikonfirmasi / selesai) bulan ini
    final sekarang = DateTime.now();
    final awalBulan = DateTime(sekarang.year, sekarang.month);
    _pendapatan = konsul
        .where('status', whereIn: [
      StatusKonsultasi.dikonfirmasi,
      StatusKonsultasi.selesai,
    ])
        .snapshots()
        .map((s) {
      var total = 0;
      for (final d in s.docs) {
        final data = d.data();
        final dibuat = data['createdAt'];
        if (dibuat is Timestamp && dibuat.toDate().isBefore(awalBulan)) {
          continue; // bukan bulan ini
        }
        total += (data['harga'] as num?)?.toInt() ?? 0;
      }
      return total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.denganJudul) ...[
          Text('Ringkasan Hari Ini', style: AppTheme.heading(18)),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            _kotak(_menunggu, 'Menunggu\nverifikasi',
                Icons.pending_actions_outlined,
                sorot: true),
            const SizedBox(width: 10),
            _kotak(_hariIni, 'Konsul\nhari ini',
                Icons.event_available_outlined),
            const SizedBox(width: 10),
            _kotak(_booking, 'Booking\nrumah', Icons.house_outlined),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _kotak(_vendor, 'Permintaan\nvendor', Icons.engineering_outlined),
            const SizedBox(width: 10),
            _kotak(_pendapatan, 'Pendapatan konsultasi\nbulan ini',
                Icons.payments_outlined,
                flex: 2, rupiah: true),
          ],
        ),
      ],
    );
  }

  /// Satu kotak angka.
  /// sorot = berubah hijau tua kalau angkanya > 0.
  /// rupiah = tampilkan sebagai Rp.
  Widget _kotak(Stream<int> stream, String label, IconData icon,
      {bool sorot = false, int flex = 1, bool rupiah = false}) {
    return Expanded(
      flex: flex,
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snap) {
          final String teks;
          if (snap.hasError) {
            teks = '–';
          } else if (!snap.hasData) {
            teks = '…';
          } else {
            teks = rupiah ? formatRupiah(snap.data!) : '${snap.data}';
          }
          final aktif = sorot && (snap.data ?? 0) > 0;
          final warnaUtama = aktif ? Colors.white : AppColors.primary;

          return Container(
            height: 112,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: aktif ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: aktif ? AppColors.primary : AdminColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: warnaUtama),
                const Spacer(),
                // FittedBox: angka besar (misal Rp1.350.000) mengecil sendiri
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    teks,
                    style: AppTheme.heading(22).copyWith(color: warnaUtama),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: aktif ? Colors.white70 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
// PERLU TINDAKAN: gabungan hal-hal yang menunggu admin
// =====================================================================

class _Tindakan {
  final IconData icon;
  final String judul;
  final String keterangan;
  final String menu; // menu yang dibuka saat diketuk
  final DateTime waktu;

  const _Tindakan(
      this.icon, this.judul, this.keterangan, this.menu, this.waktu);
}

class PerluTindakan extends StatefulWidget {
  /// Dipanggil saat item diketuk, dengan kunci menu tujuan
  /// ('konsultasi', 'perumahan', atau 'vendor')
  final ValueChanged<String> onTap;
  final bool denganJudul;

  const PerluTindakan({
    super.key,
    required this.onTap,
    this.denganJudul = true,
  });

  @override
  State<PerluTindakan> createState() => _PerluTindakanState();
}

class _PerluTindakanState extends State<PerluTindakan> {
  static const _maksTampil = 5;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _konsul;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _booking;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _vendor;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    _konsul = db
        .collection(Koleksi.konsultasi)
        .where('status', isEqualTo: StatusKonsultasi.menungguVerifikasi)
        .snapshots();
    _booking = db
        .collection(Koleksi.pesananRumah)
        .where('status', isEqualTo: StatusPesananRumah.menungguVerifikasi)
        .snapshots();
    _vendor = db
        .collection(Koleksi.permintaanVendor)
        .where('status', isEqualTo: StatusPermintaanVendor.baru)
        .snapshots();
  }

  /// Ambil teks dari dokumen. Kalau kosong, pakai teks cadangan.
  String _teks(Map<String, dynamic> m, String field, String cadangan) {
    final v = m[field]?.toString() ?? '';
    return v.isEmpty ? cadangan : v;
  }

  DateTime _waktu(Map<String, dynamic> m) {
    final t = m['createdAt'];
    return t is Timestamp ? t.toDate() : DateTime(2000);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.denganJudul) ...[
          Text('Perlu Tindakan', style: AppTheme.heading(18)),
          const SizedBox(height: 12),
        ],
        // Tiga StreamBuilder bertumpuk: menggabungkan 3 sumber data
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _konsul,
          builder: (context, s1) =>
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _booking,
                builder: (context, s2) =>
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _vendor,
                      builder: (context, s3) {
                        if (s1.hasError || s2.hasError || s3.hasError) {
                          return _kotakInfo('Gagal memuat data.');
                        }
                        if (!s1.hasData || !s2.hasData || !s3.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final items = <_Tindakan>[
                          for (final d in s1.data!.docs)
                            _Tindakan(
                              Icons.receipt_long_outlined,
                              'Bukti bayar ${_teks(d.data(), 'userNama', 'pengguna')}',
                              'Konsultasi ${_teks(d.data(), 'tanggal', '-')}',
                              'konsultasi',
                              _waktu(d.data()),
                            ),
                          for (final d in s2.data!.docs)
                            _Tindakan(
                              Icons.house_outlined,
                              'Booking ${_teks(d.data(), 'perumahanNama', 'rumah')}',
                              _teks(d.data(), 'userNama', 'Pengguna'),
                              'perumahan',
                              _waktu(d.data()),
                            ),
                          for (final d in s3.data!.docs)
                            _Tindakan(
                              Icons.engineering_outlined,
                              'Permintaan vendor · '
                                  '${_teks(d.data(), 'jenisPekerjaan', '-')}',
                              _teks(d.data(), 'userNama', 'Pengguna'),
                              'vendor',
                              _waktu(d.data()),
                            ),
                        ];

                        if (items.isEmpty) {
                          return _kotakInfo(
                              'Semua beres. Tidak ada yang perlu ditindaklanjuti.');
                        }

                        items.sort((a, b) => b.waktu.compareTo(a.waktu)); // terbaru
                        final tampil = items.take(_maksTampil).toList();
                        final sisa = items.length - tampil.length;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AdminColors.line),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < tampil.length; i++) ...[
                                if (i > 0)
                                  const Divider(height: 1, color: AdminColors.pale),
                                _baris(tampil[i]),
                              ],
                              if (sisa > 0)
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text('+$sisa lainnya',
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 12)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
        ),
      ],
    );
  }

  Widget _baris(_Tindakan t) {
    return ListTile(
      onTap: () => widget.onTap(t.menu),
      leading: CircleAvatar(
        backgroundColor: AdminColors.pale,
        child: Icon(t.icon, color: AppColors.primary, size: 20),
      ),
      title: Text(t.judul,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      subtitle: Text(t.keterangan,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }

  Widget _kotakInfo(String teks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(teks,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}