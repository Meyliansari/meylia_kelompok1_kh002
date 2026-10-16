import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/app_shell.dart';

class ConsultationAdminHomeScreen extends StatefulWidget {
  const ConsultationAdminHomeScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<ConsultationAdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<ConsultationAdminHomeScreen> {
  late int tab;
  @override
  void initState() {
    super.initState();
    tab = widget.initialTab.clamp(0, 2).toInt();
  }
  @override
  Widget build(BuildContext context) {
    final pages = [
      _VerificationPage(),
      _ArchitectsPage(),
      _SchedulePage(),
    ];
    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('RuangRancang', style: TextStyle(fontWeight: FontWeight.w700)),
        Text('Panel Administrator', style: TextStyle(fontSize: 12, color: Color(0xFF77786F))),
      ]), actions: [IconButton(onPressed: () async { await ConsultationFirestoreService.instance.db; }, icon: const Icon(Icons.notifications_none)), const SizedBox(width: 8)]),
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Verifikasi'),
          NavigationDestination(icon: Icon(Icons.engineering_outlined), selectedIcon: Icon(Icons.engineering), label: 'Arsitek'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Jadwal'),
        ]),
    );
  }
}

class ConsultationAdminTab extends StatelessWidget {
  const ConsultationAdminTab({super.key});
  @override
  Widget build(BuildContext context) => _VerificationPage();
}

class _VerificationPage extends StatelessWidget {
  _VerificationPage();
  final service = ConsultationFirestoreService.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.consultationsForAdmin(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Gagal memuat: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final waiting = docs.where((d) => d.data()['status'] == 'waiting_verification').toList();
        return ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Halo, Admin 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF203D33))),
          const SizedBox(height: 6),
          const Text('Kelola permintaan konsultasi dan validasi pembayaran.', style: TextStyle(color: Color(0xFF77786F))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _StatCard(label: 'Semua konsultasi', value: '${docs.length}', icon: Icons.event_note)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'Perlu diverifikasi', value: '${waiting.length}', icon: Icons.pending_actions)),
          ]),
          const SizedBox(height: 22),
          const SectionTitle('Perlu diverifikasi'),
          const SizedBox(height: 12),
          if (waiting.isEmpty) const _EmptyCard(message: 'Belum ada pembayaran yang menunggu verifikasi.'),
          ...waiting.map((doc) => _ConsultationCard(doc: doc)),
          const SizedBox(height: 22),
          const SectionTitle('Riwayat konsultasi'),
          const SizedBox(height: 12),
          ...docs.where((d) => d.data()['status'] != 'waiting_verification').map((doc) => _ConsultationCard(doc: doc)),
        ]);
      },
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final status = (d['status'] ?? 'unknown').toString();
    final isWaiting = ['waiting_verification', 'Paid'].contains(status);
    return Card(
      child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text((d['clientName'] ?? 'Klien').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          _StatusPill(status),
        ]),
        const SizedBox(height: 6),
        Text((d['clientNeed'] ?? d['notes'] ?? d['houseStyle'] ?? 'Konsultasi desain rumah').toString()),
        const SizedBox(height: 6),
        Text('Arsitek: ${d['architectName'] ?? '-'}', style: const TextStyle(color: Color(0xFF77786F), fontSize: 12)),
        Text('Jadwal: ${prettyDate(d['startAt'] ?? d['date'])}', style: const TextStyle(color: Color(0xFF77786F), fontSize: 12)),
        Text('Biaya: Rp${d['price'] ?? 150000}', style: const TextStyle(fontWeight: FontWeight.w600)),
        if ((d['paymentProofUrl'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showDialog(context: context, builder: (_) => Dialog(
              child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                InteractiveViewer(child: Image.network(d['paymentProofUrl'], errorBuilder: (_, __, ___) => const Text('Gambar bukti tidak dapat dimuat.'))),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
              ])),
            ),
            icon: const Icon(Icons.zoom_in), label: const Text('Lihat bukti pembayaran')),
        ],
        if (isWaiting) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _reject(context), child: const Text('Tolak'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: () => _approve(context), child: const Text('Setujui'))),
          ]),
        ],
      ])),
    );
  }

  Future<void> _approve(BuildContext context) async {
    try {
      await ConsultationFirestoreService.instance.verifyConsultation(consultationId: doc.id, approve: true);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran disetujui. Notifikasi dibuat untuk klien dan arsitek.')));
    } catch (e) { _showError(context, e); }
  }

  Future<void> _reject(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tolak pembayaran'),
      content: TextField(controller: controller, autofocus: true, maxLines: 3, decoration: const InputDecoration(labelText: 'Alasan penolakan (wajib)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(onPressed: () {
          if (controller.text.trim().isEmpty) return;
          Navigator.pop(ctx, controller.text.trim());
        }, child: const Text('Tolak')),
      ],
    ));
    controller.dispose();
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await ConsultationFirestoreService.instance.verifyConsultation(consultationId: doc.id, approve: false, reason: reason);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran ditolak dan slot dibuka kembali.')));
    } catch (e) { _showError(context, e); }
  }

  void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
  }
}

class _ArchitectsPage extends StatelessWidget {
  _ArchitectsPage();
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: ConsultationFirestoreService.instance.architects(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Gagal memuat: ${snapshot.error}'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      return ListView(padding: const EdgeInsets.all(18), children: [
        SectionTitle('Kelola arsitek', trailing: IconButton(onPressed: () => _edit(context), icon: const Icon(Icons.add_circle_outline))),
        const SizedBox(height: 12),
        const Text('Data ditarik langsung dari Cloud Firestore.', style: TextStyle(color: Color(0xFF77786F))),
        const SizedBox(height: 12),
        if (docs.isEmpty) const _EmptyCard(message: 'Belum ada data arsitek. Tekan + untuk menambahkan profil.'),
        ...docs.map((doc) {
          final d = doc.data();
          return Card(child: ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFFE5E9DD), child: const Icon(Icons.architecture, color: Color(0xFF203D33))),
            title: Text((d['name'] ?? '-').toString()),
            subtitle: Text('${d['specialty'] ?? '-'} • ${d['email'] ?? '-'}\n${d['active'] == true ? 'Aktif' : 'Nonaktif'}'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(onSelected: (v) async {
              if (v == 'edit') _edit(context, id: doc.id, data: d);
              if (v == 'toggle') {
                try { await ConsultationFirestoreService.instance.setArchitectActive(doc.id, d['active'] != true); }
                catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
              }
            }, itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Ubah profil')),
              PopupMenuItem(value: 'toggle', child: Text(d['active'] == true ? 'Nonaktifkan' : 'Aktifkan')),
            ]),
          ));
        }),
      ]);
    },
  );

  void _edit(BuildContext context, {String? id, Map<String, dynamic>? data}) {
    final name = TextEditingController(text: data?['name'] ?? '');
    final email = TextEditingController(text: data?['email'] ?? '');
    final phone = TextEditingController(text: data?['phone'] ?? '');
    final specialty = TextEditingController(text: data?['specialty'] ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(id == null ? 'Tambah arsitek' : 'Ubah profil arsitek'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
        const SizedBox(height: 8), TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 8), TextField(controller: phone, decoration: const InputDecoration(labelText: 'Nomor telepon')),
        const SizedBox(height: 8), TextField(controller: specialty, decoration: const InputDecoration(labelText: 'Spesialisasi')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(onPressed: () async {
          if (name.text.trim().isEmpty || email.text.trim().isEmpty) return;
          try {
            await ConsultationFirestoreService.instance.saveArchitect(id: id, name: name.text, email: email.text, phone: phone.text, specialty: specialty.text, active: data?['active'] != false);
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'))); }
        }, child: const Text('Simpan')),
      ],
    ));
  }
}

class _SchedulePage extends StatelessWidget {
  _SchedulePage();
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: ConsultationFirestoreService.instance.slots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Gagal memuat jadwal: ${snapshot.error}'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      return ListView(padding: const EdgeInsets.all(18), children: [
        const SectionTitle('Kelola jadwal konsultasi'),
        const SizedBox(height: 8),
        const Text('Buat 4 slot per hari, Senin–Sabtu, pukul 09.00–17.00. Slot yang sudah terisi tidak dapat ditutup.', style: TextStyle(color: Color(0xFF77786F))),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: () async {
          try {
            await ConsultationFirestoreService.instance.createWeeklySlots(DateTime.now());
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot minggu ini berhasil dibuat.')));
          } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
        }, icon: const Icon(Icons.auto_awesome), label: const Text('Buat slot minggu ini')),
        const SizedBox(height: 16),
        if (docs.isEmpty) const _EmptyCard(message: 'Belum ada jadwal. Buat slot mingguan untuk memulai.'),
        ...docs.map((doc) {
          final d = doc.data();
          final status = (d['status'] ?? 'open').toString();
          return Card(child: ListTile(
            leading: Icon(status == 'open' ? Icons.event_available : status == 'closed' ? Icons.event_busy : Icons.event),
            title: Text(prettyDate(d['startAt'])),
            subtitle: Text('Status: $status${(d['closedReason'] ?? '').toString().isNotEmpty ? '\nAlasan: ${d['closedReason']}' : ''}'),
            trailing: status == 'open' ? IconButton(tooltip: 'Tutup slot', icon: const Icon(Icons.block), onPressed: () => _close(context, doc.id)) :
              status == 'closed' ? IconButton(tooltip: 'Buka slot', icon: const Icon(Icons.lock_open), onPressed: () async {
                try { await ConsultationFirestoreService.instance.reopenSlot(doc.id); }
                catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
              }) : null,
          ));
        }),
      ]);
    },
  );

  void _close(BuildContext context, String id) {
    final reason = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tutup slot jadwal'),
      content: TextField(controller: reason, decoration: const InputDecoration(labelText: 'Alasan / hari libur'), maxLines: 2),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(onPressed: () async {
          try {
            await ConsultationFirestoreService.instance.closeSlot(id, reason.text.isEmpty ? 'Ditutup oleh admin' : reason.text);
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'))); }
        }, child: const Text('Tutup slot')),
      ],
    ));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: const Color(0xFF203D33)), const SizedBox(height: 10),
    Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF77786F))),
  ])));
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF77786F))))));
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: status == 'confirmed' || status == 'completed' ? const Color(0xFFDCE9D8) : status == 'rejected' ? const Color(0xFFF4DCD7) : const Color(0xFFECE8DB), borderRadius: BorderRadius.circular(20)),
    child: Text(status.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
  );
}
