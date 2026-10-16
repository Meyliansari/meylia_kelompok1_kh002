import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/proyek.dart';
import '../../services/auth_service.dart';
import '../../services/proyek_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gambar_proyek.dart';
import 'admin_ringkasan.dart'; // AdminColors
import 'admin_widgets.dart';

// =====================================================================
// HALAMAN 1: DAFTAR PROYEK
// =====================================================================

class AdminProyekPage extends StatefulWidget {
  const AdminProyekPage({super.key});

  @override
  State<AdminProyekPage> createState() => _AdminProyekPageState();
}

class _AdminProyekPageState extends State<AdminProyekPage> {
  late final Stream<List<Proyek>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = ProyekService.streamSemua();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  void _bukaForm(Proyek? p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminProyekFormPage(proyek: p)),
    );
  }

  Future<void> _isiContoh() async {
    try {
      await ProyekService.isiContoh();
      _pesan('3 proyek contoh ditambahkan.');
    } catch (e) {
      _pesan(AuthService.errorMessage(e));
    }
  }

  Future<void> _ubahTampil(Proyek p, bool v) async {
    try {
      await ProyekService.setTampil(p.id, v);
    } catch (e) {
      _pesan(AuthService.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _bukaForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Proyek'),
      ),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Proyek>>(
          stream: _stream,
          builder: (context, snap) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 96), // ruang untuk tombol
              children: [
                const AdminPageHeader(
                  icon: Icons.photo_library_rounded,
                  judul: 'Kelola Proyek',
                  subjudul: 'Proyek yang tampil di Beranda pengguna.',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AdminSection(
                    icon: Icons.collections_outlined,
                    judul: 'Daftar Proyek',
                    children: [_isiDaftar(snap)],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _isiDaftar(AsyncSnapshot<List<Proyek>> snap) {
    if (snap.hasError) {
      return Text('Gagal memuat: ${AuthService.errorMessage(snap.error!)}',
          style: const TextStyle(color: Colors.red));
    }
    if (!snap.hasData) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final list = snap.data!;
    if (list.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Belum ada proyek.',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isiContoh,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Isi 3 proyek contoh'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in list) _kartu(p),
        const SizedBox(height: 4),
        const Text(
          'Proyek dengan sakelar mati tidak tampil di Beranda.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _kartu(Proyek p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Opacity(
              opacity: p.tampil ? 1 : 0.4,
              child: GambarProyek(p.gambar,
                  width: 72, height: 56, cacheWidth: 200),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(p.kota,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                Text('Urutan ${p.urutan}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: p.tampil,
            activeTrackColor: AdminUi.army,
            onChanged: (v) => _ubahTampil(p, v),
          ),
          IconButton(
            tooltip: 'Ubah',
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => _bukaForm(p),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// HALAMAN 2: FORM TAMBAH / UBAH PROYEK
// =====================================================================

class AdminProyekFormPage extends StatefulWidget {
  final Proyek? proyek; // null = tambah baru

  const AdminProyekFormPage({super.key, this.proyek});

  @override
  State<AdminProyekFormPage> createState() => _AdminProyekFormPageState();
}

class _AdminProyekFormPageState extends State<AdminProyekFormPage> {
  /// Foto yang sudah ada di folder lib/images (bisa ditambah sendiri)
  static const _galeri = [
    'lib/images/rumahdashboard1.jpg',
    'lib/images/rumahdashboard2.jpg',
    'lib/images/rumahdashboard3.jpg',
    'lib/images/rumahdashboard4.jpg',
    'lib/images/dashboardperumahan1.jpg',
    'lib/images/dashboardperumahan2.jpg',
    'lib/images/dashboardperumahan3.jpg',
    'lib/images/dashboardkonsul.jpg',
    'lib/images/houselogin.jpg',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _kota = TextEditingController();
  final _url = TextEditingController();
  final _urutan = TextEditingController();

  late String _gambar;
  late bool _tampil;
  bool _saving = false;

  bool get _modeUbah => widget.proyek != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proyek;
    _nama.text = p?.nama ?? '';
    _kota.text = p?.kota ?? '';
    _urutan.text = '${p?.urutan ?? 0}';
    _gambar = p?.gambar ?? _galeri.first;
    _tampil = p?.tampil ?? true;
    if (_gambar.startsWith('http')) _url.text = _gambar;

    // Pratinjau ikut berubah saat mengetik
    _nama.addListener(() => setState(() {}));
    _kota.addListener(() => setState(() {}));
    _url.addListener(() {
      final link = _url.text.trim();
      if (link.startsWith('http')) setState(() => _gambar = link);
    });
  }

  @override
  void dispose() {
    _nama.dispose();
    _kota.dispose();
    _url.dispose();
    _urutan.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ProyekService.simpan(Proyek(
        id: widget.proyek?.id ?? '',
        nama: _nama.text.trim(),
        kota: _kota.text.trim(),
        gambar: _gambar,
        tampil: _tampil,
        urutan: int.tryParse(_urutan.text) ?? 0,
      ));
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
          content: Text(_modeUbah ? 'Proyek diperbarui.' : 'Proyek ditambahkan.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.errorMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _hapus() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Hapus proyek?', style: AppTheme.heading(18)),
        content: Text('"${widget.proyek!.nama}" akan dihapus permanen. '
            'Kalau hanya ingin disembunyikan, matikan sakelarnya saja.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus',
                style: TextStyle(
                    color: Colors.red.shade700, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;

    try {
      await ProyekService.hapus(widget.proyek!.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Proyek dihapus.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AdminPageHeader(
                icon: _modeUbah
                    ? Icons.edit_note_rounded
                    : Icons.add_photo_alternate_rounded,
                judul: _modeUbah ? 'Ubah Proyek' : 'Tambah Proyek',
                subjudul: 'Data proyek untuk Beranda pengguna.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _seksiPratinjau(),
                    _seksiData(),
                    _seksiGambar(),
                    ElevatedButton(
                      onPressed: _saving ? null : _simpan,
                      child: _saving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : Text(_modeUbah
                          ? 'Simpan Perubahan'
                          : 'Tambah Proyek'),
                    ),
                    if (_modeUbah) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _hapus,
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade700),
                        label: Text('Hapus proyek',
                            style: TextStyle(color: Colors.red.shade700)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pratinjau: kira-kira begini tampilannya di Beranda
  Widget _seksiPratinjau() {
    return AdminSection(
      icon: Icons.visibility_outlined,
      judul: 'Pratinjau',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: GambarProyek(_gambar,
              width: double.infinity, height: 170, cacheWidth: 900),
        ),
        const SizedBox(height: 10),
        Text(_nama.text.isEmpty ? 'Nama proyek' : _nama.text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        Text(_kota.text.isEmpty ? 'Kota' : _kota.text,
            style: const TextStyle(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _seksiData() {
    return AdminSection(
      icon: Icons.edit_note,
      judul: 'Data Proyek',
      children: [
        AdminFieldRow(
          icon: Icons.home_work_outlined,
          label: 'Nama proyek',
          child: TextFormField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            decoration: adminInput(hint: 'Rumah Tropis Modern'),
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
        ),
        AdminFieldRow(
          icon: Icons.location_on_outlined,
          label: 'Kota',
          child: TextFormField(
            controller: _kota,
            textCapitalization: TextCapitalization.words,
            decoration: adminInput(hint: 'Bandung'),
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Kota wajib diisi' : null,
          ),
        ),
        AdminFieldRow(
          icon: Icons.format_list_numbered,
          label: 'Urutan tampil',
          child: TextFormField(
            controller: _urutan,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: adminInput(hint: '0 = paling depan'),
          ),
        ),
        Row(
          children: [
            const Expanded(
              child: Text('Tampilkan di Beranda',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            Switch(
              value: _tampil,
              activeTrackColor: AdminUi.army,
              onChanged: (v) => setState(() => _tampil = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _seksiGambar() {
    return AdminSection(
      icon: Icons.photo_library_outlined,
      judul: 'Pilih Gambar',
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.3,
          children: [
            for (final g in _galeri)
              GestureDetector(
                onTap: () => setState(() {
                  _gambar = g;
                  _url.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                      _gambar == g ? AdminUi.army : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GambarProyek(g, cacheWidth: 300),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Atau tempel link gambar dari internet',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _url,
          keyboardType: TextInputType.url,
          decoration: adminInput(hint: 'https://...'),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isNotEmpty && !t.startsWith('http')) {
              return 'Link harus diawali http';
            }
            return null;
          },
        ),
      ],
    );
  }
}