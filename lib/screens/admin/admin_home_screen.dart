import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/after_login.dart';
import '../home/coming_soon_tab.dart';
import 'admin_pengaturan_page.dart';
import 'admin_ringkasan.dart';
import 'admin_widgets.dart';
import 'admin_pengguna_page.dart';
import 'admin_proyek_page.dart';
import '../../consultation_module/screens/admin_home_screen.dart';

/// Satu menu Kelola.
/// page = halaman tujuan. null = belum dibuat (dikerjakan anggota lain).
class _MenuAdmin {
  final String kunci; // dipakai "Perlu Tindakan" untuk membuka menu ini
  final IconData icon;
  final String judul;
  final String keterangan;
  final Widget? page;
  final String pemegang;

  const _MenuAdmin(this.kunci, this.icon, this.judul, this.keterangan,
      this.page, this.pemegang);
}

/// Dashboard Admin: 4 tab (Dashboard, Konsultasi, Kelola, Atur).
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _tab = 0;
  String _nama = 'Admin';

  // Saat halaman teman sudah jadi, ganti `null` dengan halamannya,
  // misal: const AdminKonsultasiPage()
  static const _menu = [
    _MenuAdmin('konsultasi', Icons.assignment_outlined, 'Konsultasi',
        'Verifikasi & tugaskan', const ConsultationAdminHomeScreen(initialTab: 0), 'Anggota 3'),
    _MenuAdmin('jadwal', Icons.architecture_outlined, 'Arsitek & Jadwal',
        'Slot jam, hari libur', const ConsultationAdminHomeScreen(initialTab: 2), 'Anggota 3'),
    _MenuAdmin('pengguna', Icons.group_outlined, 'Pengguna',
        'Aktif / nonaktif, role', AdminPenggunaPage(), 'Anggota 1'),
    _MenuAdmin('perumahan', Icons.house_outlined, 'Perumahan',
        'Listing & booking', null, 'Anggota 4'),
    _MenuAdmin('vendor', Icons.engineering_outlined, 'Vendor',
        'Vendor & permintaan', null, 'Anggota 5'),
    _MenuAdmin('proyek', Icons.photo_library_outlined, 'Proyek',
        'Proyek terbaru di Beranda', AdminProyekPage(), 'Anggota 1'),
    _MenuAdmin('pengaturan', Icons.tune, 'Pengaturan',
        'Harga, rekening, aturan', AdminPengaturanPage(), 'Anggota 1'),
  ];

  @override
  void initState() {
    super.initState();
    _loadNama();
  }

  Future<void> _loadNama() async {
    final profile = await AuthService().getUserProfile();
    if (!mounted) return;
    setState(() => _nama = profile?['nama'] ?? 'Admin');
  }

  /// Contoh: "Sabtu, 3 Oktober 2026"
  String _tanggalHariIni() {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final n = DateTime.now();
    return '${hari[n.weekday - 1]}, ${n.day} ${bulan[n.month - 1]} ${n.year}';
  }

  void _bukaMenu(_MenuAdmin m) {
    final page = m.page;
    if (page == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${m.judul} segera hadir (${m.pemegang})')),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Dipanggil dari "Perlu Tindakan" dengan kunci menu
  void _bukaKunci(String kunci) =>
      _bukaMenu(_menu.firstWhere((m) => m.kunci == kunci));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            _buildDashboard(),
            // ↓ Nanti diganti: const AdminKonsultasiPage() (Anggota 3)
            const ConsultationAdminTab(),
            _buildKelola(),
            const AdminPengaturanPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AdminColors.soft,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
            label: 'Konsultasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: AppColors.primary),
            label: 'Kelola',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune, color: AppColors.primary),
            label: 'Atur',
          ),
        ],
      ),
    );
  }

  // =================== TAB 1: DASHBOARD ===================

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        AdminPageHeader(
          icon: Icons.home_work_rounded,
          judul: 'RuangRancang',
          subjudul: 'Panel Admin',
          aksi: [_tombolNotifikasi(), _tombolAkun()],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sapaan + tanggal + jam
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, $_nama', style: AppTheme.heading(22)),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${_tanggalHariIni()} · ',
                            style:
                            const TextStyle(color: AppColors.textMuted)),
                        const JamLive(),
                      ],
                    ),
                  ],
                ),
              ),
              const AdminSection(
                icon: Icons.insights_outlined,
                judul: 'Ringkasan Hari Ini',
                children: [RingkasanAdmin(denganJudul: false)],
              ),
              AdminSection(
                icon: Icons.notifications_active_outlined,
                judul: 'Perlu Tindakan',
                children: [
                  PerluTindakan(onTap: _bukaKunci, denganJudul: false),
                ],
              ),
              AdminSection(
                icon: Icons.grid_view_outlined,
                judul: 'Kelola',
                children: [
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.0,
                    children: [for (final m in _menu) _menuKecil(m)],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tombolNotifikasi() {
    return IconButton(
      tooltip: 'Notifikasi',
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Notifikasi admin segera hadir (Anggota 5)')),
      ),
      icon: const Icon(Icons.notifications_none, color: AppColors.primary),
    );
  }

  /// Foto profil: ketuk untuk menu Keluar
  Widget _tombolAkun() {
    final inisial = _nama.isNotEmpty ? _nama[0].toUpperCase() : 'A';
    return PopupMenuButton<String>(
      tooltip: 'Akun',
      onSelected: (v) {
        if (v == 'keluar') logoutAndGoToLogin(context);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'keluar',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 10),
              Text('Keluar'),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary,
        child: Text(inisial,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// Kartu kecil 3 kolom di Dashboard (ikon + judul)
  Widget _menuKecil(_MenuAdmin m) {
    final aktif = m.page != null;
    final warna = aktif ? Colors.white : AppColors.textMuted;
    return Material(
      color: aktif ? AdminUi.army : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _bukaMenu(m),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border:
            Border.all(color: aktif ? AdminUi.army : AdminColors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(m.icon, color: warna),
              const SizedBox(height: 6),
              Text(
                m.judul,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600, color: warna),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================== TAB 3: KELOLA ===================

  Widget _buildKelola() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const AdminPageHeader(
          icon: Icons.grid_view_rounded,
          judul: 'Kelola',
          subjudul: 'Pilih data yang ingin dikelola.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AdminSection(
            icon: Icons.dashboard_customize_outlined,
            judul: 'Menu Kelola',
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [for (final m in _menu) _menuCard(m)],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Kartu besar 2 kolom di tab Kelola (ikon + judul + keterangan)
  Widget _menuCard(_MenuAdmin m) {
    final aktif = m.page != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _bukaMenu(m),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
            Border.all(color: aktif ? AdminUi.army : AdminColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: aktif ? AdminUi.army : AdminUi.iconBg,
                child: Icon(m.icon,
                    size: 20,
                    color: aktif ? Colors.white : AppColors.textMuted),
              ),
              const Spacer(),
              Text(
                m.judul,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: aktif ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                aktif ? m.keterangan : 'Segera hadir · ${m.pemegang}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}