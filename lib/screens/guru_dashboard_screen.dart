// lib/screens/guru_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../models/guru.dart';
import 'login_screen.dart';
import 'iot_setup_screen.dart';
import 'guru_topup_screen.dart';
import 'guru_student_list_screen.dart';
import 'guru_menu_screen.dart';

class GuruDashboardScreen extends StatefulWidget {
  const GuruDashboardScreen({super.key});

  @override
  State<GuruDashboardScreen> createState() => _GuruDashboardScreenState();
}

class _GuruDashboardScreenState extends State<GuruDashboardScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _onLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Yakin ingin keluar dari AzagasPay?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: AppColors.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Keluar',
                style: GoogleFonts.poppins(
                    color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  void _onFeatureTap(int index, BuildContext ctx) {
    switch (index) {
      case 0:
        Navigator.of(ctx).push(
          MaterialPageRoute(builder: (_) => const GuruStudentListScreen()));
      case 1:
        Navigator.of(ctx).push(
          MaterialPageRoute(builder: (_) => const GuruTopupScreen()));
      case 2:
        Navigator.of(ctx).push(
          MaterialPageRoute(builder: (_) => const GuruMenuScreen()));
      case 3:
        Navigator.of(ctx).push(
          MaterialPageRoute(builder: (_) => const IotSetupScreen()));
    }
  }

  static const List<_GuruFeature> _features = [
    _GuruFeature(
      title: 'Daftar Siswa',
      subtitle: 'Lihat & kelola data siswa',
      icon: Icons.people_rounded,
      color: Color(0xFF4F8EF7),
    ),
    _GuruFeature(
      title: 'Top-up Saldo',
      subtitle: 'Isi ulang saldo siswa',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF43C59E),
    ),
    _GuruFeature(
      title: 'Kelola Menu',
      subtitle: 'Tambah, edit, hapus menu',
      icon: Icons.restaurant_menu_rounded,
      color: Color(0xFFFF8C42),
    ),
    _GuruFeature(
      title: 'Perangkat IoT',
      subtitle: 'Kelola perangkat NFC',
      icon: Icons.settings_input_antenna_rounded,
      color: Color(0xFF9B59B6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final guru = auth.guru;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(children: [
            _buildHeader(guru),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(guru),
                    const SizedBox(height: 20),
                    Text('Menu Pengelolaan',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _buildFeaturesGrid(context),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildHeader(Guru? guru) => Container(
    decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Halo, ${guru?.name.split(' ').first ?? ''} 👋',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.white70)),
              GestureDetector(
                onTap: _onLogout,
                child: _headerIcon(Icons.logout_rounded)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Panel Guru',
                style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              _roleBadge(guru?.displayRole ?? 'Guru'),
            ],
          ),
        ]),
      ),
    ),
  );

  Widget _headerIcon(IconData icon) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(10)),
    child: Icon(icon, color: Colors.white, size: 18),
  );

  Widget _roleBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: Colors.white.withValues(alpha: 0.4), width: 1)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.white)),
    ]),
  );

  Widget _buildInfoCard(Guru? guru) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.school_rounded, color: Colors.white, size: 24)),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(guru?.name ?? '-',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
          Text(guru?.displayRole ?? 'Guru',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textMuted)),
        ],
      )),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8)),
        child: Text('Aktif',
            style: GoogleFonts.poppins(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32))),
      ),
    ]),
  );

  Widget _buildFeaturesGrid(BuildContext ctx) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
    ),
    itemCount: _features.length,
    itemBuilder: (_, i) => _featureCard(_features[i], i, ctx),
  );

  Widget _featureCard(_GuruFeature feature, int index, BuildContext ctx) =>
      GestureDetector(
        onTap: () => _onFeatureTap(index, ctx),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: feature.color.withValues(alpha: 0.12),
                blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(feature.icon, color: feature.color, size: 22)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(feature.title,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(feature.subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textMuted),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ],
          ),
        ),
      );
}

class _GuruFeature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _GuruFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
