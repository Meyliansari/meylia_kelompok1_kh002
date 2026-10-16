import 'package:flutter/material.dart';
import '../../models/proyek.dart';
import '../../services/proyek_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gambar_proyek.dart';

/// Semua proyek yang ditampilkan (dibuka dari "Lihat Semua" di Beranda)
class SemuaProyekPage extends StatelessWidget {
  const SemuaProyekPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proyek Kami')),
      body: StreamBuilder<List<Proyek>>(
        stream: ProyekService.streamTampil(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Gagal memuat proyek.'));
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
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final p = list[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GambarProyek(p.gambar,
                        width: double.infinity, height: 140, cacheWidth: 500),
                  ),
                  const SizedBox(height: 8),
                  Text(p.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text(p.kota,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}