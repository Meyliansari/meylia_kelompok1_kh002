import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'admin_ringkasan.dart'; // AdminColors

/// Warna tambahan khusus tampilan admin
class AdminUi {
  AdminUi._();
  static const army = Color(0xFF7A9270); // tombol hari/slot yang aktif
  static const strip = Color(0xFFE7ECDF); // strip judul kartu
  static const iconBg = Color(0xFFDCE5D3); // lingkaran di belakang ikon
}

// =====================================================================
// HEADER HALAMAN: ikon + judul + subjudul + foto rumah transparan
// =====================================================================

class AdminPageHeader extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String subjudul;
  final List<Widget> aksi; // tombol di kanan atas (opsional)

  const AdminPageHeader({
    super.key,
    required this.icon,
    required this.judul,
    required this.subjudul,
    this.aksi = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Kalau halaman dibuka dari menu (bukan tab), tampilkan tombol kembali
    final bisaKembali = Navigator.of(context).canPop();

    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          // Foto rumah di kanan, memudar ke kiri
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 200,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.black],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Opacity(
                opacity: 0.45,
                child: Image.asset(
                  'lib/images/houselogin.jpg',
                  fit: BoxFit.cover,
                  cacheWidth: 500,
                ),
              ),
            ),
          ),

          // Ikon + tulisan
          Padding(
            padding: EdgeInsets.fromLTRB(bisaKembali ? 4 : 20, 16, 110, 16),
            child: Row(
              children: [
                if (bisaKembali)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                Icon(icon, size: 46, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(judul, style: AppTheme.heading(22)),
                      const SizedBox(height: 4),
                      Text(
                        subjudul,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tombol-tombol di kanan atas (lonceng, foto profil, dll.)
          if (aksi.isNotEmpty)
            Positioned(
              top: 6,
              right: 10,
              child: Row(children: aksi),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
// KARTU BAGIAN: strip judul sage + isi
// =====================================================================

class AdminSection extends StatelessWidget {
  final IconData icon;
  final String judul;
  final List<Widget> children;

  const AdminSection({
    super.key,
    required this.icon,
    required this.judul,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.line.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Strip judul
          Container(
            color: AdminUi.strip,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 26),
                const SizedBox(width: 12),
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Isi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// BARIS ISIAN: ikon bulat di kiri, label di atas kolom
// =====================================================================

class AdminFieldRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Widget child;

  const AdminFieldRow({
    super.key,
    this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AdminUi.iconBg,
                child: Icon(icon, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gaya kotak isian admin: putih, tepi tipis, label kecil di kanan (opsional)
InputDecoration adminInput({String? prefix, String? hint, String? suffix}) {
  OutlineInputBorder tepi(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c, width: w),
  );

  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    hintText: hint,
    prefixText: prefix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    suffixIcon: suffix == null
        ? null
        : Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AdminUi.strip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(suffix,
          style: const TextStyle(color: AppColors.textMuted)),
    ),
    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    enabledBorder: tepi(AdminColors.line),
    focusedBorder: tepi(AppColors.primary, 1.5),
    errorBorder: tepi(Colors.red.shade300),
    focusedErrorBorder: tepi(Colors.red, 1.5),
  );
}

// =====================================================================
// TOMBOL PILIHAN (hari / slot jam)
// =====================================================================

class AdminPilihChip extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback? onTap;
  final VoidCallback? onHapus; // kalau diisi, muncul ikon ✕

  const AdminPilihChip({
    super.key,
    required this.label,
    required this.aktif,
    this.onTap,
    this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: aktif ? AdminUi.army : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 40,
          constraints: const BoxConstraints(minWidth: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: aktif ? AdminUi.army : AdminColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: aktif ? Colors.white : AppColors.textMuted,
                ),
              ),
              if (onHapus != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onHapus,
                  child: Icon(Icons.close,
                      size: 16,
                      color: aktif ? Colors.white : AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}