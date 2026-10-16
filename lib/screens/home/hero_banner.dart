import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Banner besar di Beranda: foto bergeser otomatis tiap 4 detik,
/// sementara judul, deskripsi, dan kolom pencarian tetap diam di atasnya.
class HeroBanner extends StatefulWidget {
  final List<String> images; // daftar path foto di lib/images/
  final VoidCallback onSearchTap;

  const HeroBanner({
    super.key,
    required this.images,
    required this.onSearchTap,
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  static const _interval = Duration(seconds: 4);

  final _controller = PageController();
  Timer? _timer;
  int _current = 0; // foto yang sedang tampil

  @override
  void initState() {
    super.initState();
    // Hanya perlu bergeser kalau fotonya lebih dari satu
    if (widget.images.length > 1) {
      _timer = Timer.periodic(_interval, (_) => _nextPage());
    }
  }

  void _nextPage() {
    if (!_controller.hasClients) return;
    // Modulo (%) membuat urutan berputar: 0 → 1 → 2 → 3 → 0 → ...
    final next = (_current + 1) % widget.images.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    // WAJIB: matikan timer & controller saat halaman ditutup,
    // supaya tidak terus berjalan di belakang dan bikin error.
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Lapisan 1: foto-foto yang bergeser
              PageView.builder(
                controller: _controller,
                itemCount: widget.images.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) =>
                    Image.asset(widget.images[i], fit: BoxFit.cover),
              ),

              // Lapisan 2: gradasi gelap. IgnorePointer = sentuhan "tembus"
              // ke foto di bawahnya, jadi foto tetap bisa digeser manual.
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0xB3000000)],
                    ),
                  ),
                ),
              ),

              // Lapisan 3: tulisan, indikator, dan pencarian (diam)
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rancang Rumah,\nWujudkan Hidup',
                            style: AppTheme.heading(26)
                                .copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Konsultasi, Bangun, dan Temukan Rumah Impianmu '
                                'dalam Satu Aplikasi.',
                            style:
                            TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          _buildDots(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Titik indikator: titik foto yang aktif lebih panjang.
  Widget _buildDots() {
    return Row(
      children: List.generate(widget.images.length, (i) {
        final active = i == _current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white54,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: widget.onSearchTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.textMuted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cari desain, arsitek, vendor, atau perumahan...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}