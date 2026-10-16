import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../consultation_history_screen.dart'; // Jalur import diperbaiki
import 'beranda_tab.dart';
import 'coming_soon_tab.dart';
import 'profil_tab.dart';

/// Cangkang Beranda User: memegang bar bawah dan menampilkan tab yang dipilih.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0; // tab yang sedang aktif
  String _nama = '';

  @override
  void initState() {
    super.initState();
    _loadNama();
  }

  Future<void> _loadNama() async {
    final profile = await AuthService().getUserProfile();
    if (!mounted) return;
    setState(() => _nama = profile?['nama'] ?? '');
  }

  void _openTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'user_guest';

    final List<Widget> pages = [
      BerandaTab(nama: _nama, onOpenTab: _openTab),
      ConsultationHistoryScreen(userId: currentUserId),
      const ComingSoonTab(
          title: 'Vendor Konstruksi', icon: Icons.engineering_outlined),
      const ComingSoonTab(title: 'Perumahan', icon: Icons.house_outlined),
      const ProfilTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _openTab,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.design_services_outlined),
            selectedIcon:
            Icon(Icons.design_services, color: AppColors.primary),
            label: 'Konsultasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.engineering_outlined),
            selectedIcon: Icon(Icons.engineering, color: AppColors.primary),
            label: 'Vendor',
          ),
          NavigationDestination(
            icon: Icon(Icons.house_outlined),
            selectedIcon: Icon(Icons.house, color: AppColors.primary),
            label: 'Perumahan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}