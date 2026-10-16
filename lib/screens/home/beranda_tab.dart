import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/pengaturan.dart';
import '../../models/proyek.dart';
import '../../services/pengaturan_service.dart';
import '../../services/proyek_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/gambar_proyek.dart';
import '../../consultation_booking_screen.dart'; // Jalur import diperbaiki
import 'beranda_kontak.dart';
import 'hero_banner.dart';
import 'semua_proyek_page.dart';

/// Tab Beranda (dashboard user).
class BerandaTab extends StatelessWidget {
  final String nama;

  /// Dipanggil saat menu/tombol ingin membuka tab lain (1 = Konsultasi, dst.)
  final ValueChanged<int> onOpenTab;

  const BerandaTab({super.key, required this.nama, required this.onOpenTab});

  /// Foto banner yang bergeser otomatis
  static const _bannerImages = [
    'lib/images/rumahdashboard1.jpg',
    'lib/images/rumahdashboard2.jpg',
    'lib/images/rumahdashboard3.jpg',
    'lib/images/rumahdashboard4.jpg',
  ];

  static const _promoImage = 'lib/images/dashboardkonsul.jpg';

  void _bukaHalamanKonsultasi(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'user_guest';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationBookingScreen(userId: currentUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          HeroBanner(
            images: _bannerImages,
            onSearchTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur pencarian segera hadir')),
            ),
          ),
          const SizedBox(height: 16),
          _buildMenu(context),
          const SizedBox(height: 20),
          _buildPromo(context),
          const SizedBox(height: 24),
          _buildProyekHeader(context),
          const SizedBox(height: 8),
          _buildProyekList(),
          const SizedBox(height: 24),
          const KontakDarurat(),
          const SizedBox(height: 28),
          const BerandaFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, color: AppColors.primary, size: 28),
          const SizedBox(width: 8),
          Text('RuangRancang', style: AppTheme.heading(20)),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _menuCard(
            Icons.design_services_outlined,
            'Konsultasi\nDesain',
                () => _bukaHalamanKonsultasi(context),
          ),
          const SizedBox(width: 12),
          _menuCard(
            Icons.engineering_outlined,
            'Vendor\nKonstruksi',
                () => onOpenTab(2),
          ),
          const SizedBox(width: 12),
          _menuCard(
            Icons.house_outlined,
            'Perumahan',
                () => onOpenTab(3),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 104,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 170,
          color: AppColors.primary,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Konsultasi Desain Rumah',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<Pengaturan>(
                        stream: PengaturanService.stream(),
                        initialData: Pengaturan.bawaan,
                        builder: (context, snap) {
                          final p = snap.data ?? Pengaturan.bawaan;
                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: formatRupiah(p.hargaKonsultasi),
                                  style: AppTheme.heading(24)
                                      .copyWith(color: Colors.white),
                                ),
                                TextSpan(
                                  text: ' / ${p.durasiKonsultasi}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Dapatkan desain terbaik bersama arsitek profesional.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _bukaHalamanKonsultasi(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Lihat Detail  →',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Image.asset(
                  _promoImage,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  cacheWidth: 600,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white12,
                    child: const Icon(Icons.image_not_supported, color: Colors.white54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProyekHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8),
      child: Row(
        children: [
          Text('Proyek Terbaru', style: AppTheme.heading(18)),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SemuaProyekPage()),
            ),
            child: const Text(
              'Lihat Semua  →',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProyekList() {
    return SizedBox(
      height: 180,
      child: StreamBuilder<List<Proyek>>(
        stream: ProyekService.streamTampil(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('Gagal memuat proyek.',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(
              child: Text('Belum ada proyek.',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = list[i];
              return SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GambarProyek(p.gambar,
                          width: 150, height: 110, cacheWidth: 400),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      p.kota,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}