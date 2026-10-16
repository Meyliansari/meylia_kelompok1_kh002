import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../widgets/app_shell.dart';

class ConsultationArchitectHomeScreen extends StatelessWidget {
  const ConsultationArchitectHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'RuangRancang',
      subtitle: 'Beranda Arsitek',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ConsultationFirestoreService.instance.consultationsForArchitect(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Gagal memuat tugas: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final av = a.data()['startAt'];
              final bv = b.data()['startAt'];
              final ad = av is Timestamp ? av.toDate() : DateTime(2100);
              final bd = bv is Timestamp ? bv.toDate() : DateTime(2100);
              return ad.compareTo(bd);
            });
          final active = docs.where((d) => ['confirmed', 'in_progress'].contains(d.data()['status'])).toList();
          final today = DateTime.now();
          final todays = active.where((d) {
            final v = d.data()['startAt'];
            if (v is! Timestamp) return false;
            final date = v.toDate();
            return date.year == today.year && date.month == today.month && date.day == today.day;
          }).toList();
          return ListView(padding: const EdgeInsets.all(18), children: [
            const Text('Selamat bekerja 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF203D33))),
            const SizedBox(height: 6),
            const Text('Berikut jadwal dan tugas konsultasi kamu.', style: TextStyle(color: Color(0xFF77786F))),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _Metric(label: 'Tugas hari ini', value: '${todays.length}', icon: Icons.today)),
              const SizedBox(width: 10),
              Expanded(child: _Metric(label: 'Tugas aktif', value: '${active.length}', icon: Icons.assignment_outlined)),
            ]),
            const SizedBox(height: 22),
            const SectionTitle('Jadwal & tugas'),
            const SizedBox(height: 10),
            if (docs.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada konsultasi yang ditugaskan ke akun ini.'))),
            ...docs.map((doc) => _ArchitectConsultationCard(doc: doc)),
          ]);
        },
      ),
    );
  }
}

class _ArchitectConsultationCard extends StatelessWidget {
  const _ArchitectConsultationCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final status = (d['status'] ?? 'unknown').toString();
    return Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text((d['clientName'] ?? 'Klien').toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        _StatusBadge(status),
      ]),
      const SizedBox(height: 7),
      Text(prettyDate(d['startAt']), style: const TextStyle(color: Color(0xFF77786F), fontSize: 12)),
      const SizedBox(height: 8),
      Text('Kebutuhan: ${d['clientNeed'] ?? '-'}'),
      Text('Kontak: ${d['clientPhone'] ?? '-'}'),
      if ((d['meetingUrl'] ?? '').toString().isNotEmpty) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => _openUrl(context, d['meetingUrl'].toString()), icon: const Icon(Icons.video_call_outlined), label: const Text('Buka link meeting')),
      ],
      if (status == 'confirmed') ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => _start(context, doc.id), icon: const Icon(Icons.play_arrow), label: const Text('Mulai konsultasi')),
      ],
      if (status == 'confirmed' || status == 'in_progress') ...[
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: () => _complete(context, doc.id), icon: const Icon(Icons.task_alt), label: const Text('Isi hasil & tandai selesai')),
      ],
      if (status == 'completed') ...[
        const Divider(height: 22),
        const Text('Hasil konsultasi', style: TextStyle(fontWeight: FontWeight.w700)),
        Text((d['resultNotes'] ?? 'Belum ada catatan').toString()),
        if ((d['recommendations'] ?? '').toString().isNotEmpty) Text('Rekomendasi: ${d['recommendations']}'),
        if ((d['designFileUrl'] ?? '').toString().isNotEmpty) Text('File desain: ${d['designFileUrl']}'),
      ],
    ])));
  }

  Future<void> _start(BuildContext context, String id) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Mulai konsultasi'),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Link meeting (opsional)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Mulai')),
      ],
    ));
    controller.dispose();
    if (url == null) return;
    try {
      await ConsultationFirestoreService.instance.startConsultation(id, url);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konsultasi dimulai.')));
    } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }

  Future<void> _complete(BuildContext context, String id) async {
    final notes = TextEditingController();
    final recommendations = TextEditingController();
    final file = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hasil konsultasi'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Catatan konsultasi *')),
        const SizedBox(height: 8),
        TextField(controller: recommendations, maxLines: 3, decoration: const InputDecoration(labelText: 'Rekomendasi')),
        const SizedBox(height: 8),
        TextField(controller: file, decoration: const InputDecoration(labelText: 'URL file desain (opsional)')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        ElevatedButton(onPressed: () {
          if (notes.text.trim().isEmpty) return;
          Navigator.pop(ctx, true);
        }, child: const Text('Selesaikan')),
      ],
    ));
    if (ok != true) { notes.dispose(); recommendations.dispose(); file.dispose(); return; }
    try {
      await ConsultationFirestoreService.instance.finishConsultation(consultationId: id, notes: notes.text, recommendations: recommendations.text, designFileUrl: file.text);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konsultasi selesai. Notifikasi dibuat untuk pengguna.')));
    } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    notes.dispose(); recommendations.dispose(); file.dispose();
  }

  Future<void> _openUrl(BuildContext context, String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link tidak valid atau tidak dapat dibuka.')));
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: const Color(0xFF203D33)), const SizedBox(height: 10),
    Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF77786F))),
  ])));
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: status == 'confirmed' || status == 'completed' ? const Color(0xFFDCE9D8) : status == 'rejected' ? const Color(0xFFF4DCD7) : const Color(0xFFECE8DB), borderRadius: BorderRadius.circular(20)),
    child: Text(status.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
  );
}
