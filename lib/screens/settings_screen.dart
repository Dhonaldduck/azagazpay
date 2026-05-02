// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_center_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _onLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Yakin ingin keluar dari AzagasPay?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: AppColors.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Keluar',
                style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      final auth = context.read<AuthProvider>();
      await auth.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthProvider>().student;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(student?.name ?? 'Siswa'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(student),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Informasi Aplikasi'),
                  const SizedBox(height: 12),
                  _buildAppInfoCard(context),
                  const SizedBox(height: 24),
                  _buildLogoutButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(String name) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Pengaturan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildProfileCard(student) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(student?.avatarUrl ?? 'https://ui-avatars.com/api/?name=Siswa&background=random'),
          ),
          const SizedBox(height: 16),
          Text(
            student?.name ?? 'Nama Siswa',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'NISN: ${student?.nisn ?? '-'}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const Divider(height: 32, thickness: 1, color: AppColors.border),
          _buildInfoRow(Icons.class_outlined, 'Kelas', student?.studentClass ?? '-'),
          _buildInfoRow(Icons.wc_outlined, 'Jenis Kelamin', student?.gender ?? 'Laki-laki'),
          _buildInfoRow(Icons.calendar_month_outlined, 'Tanggal Lahir', student?.dateOfBirth ?? '1 Januari 2010'),
          _buildInfoRow(Icons.phone_android_outlined, 'Nomor Telepon', student?.phoneNumber ?? '0812-3456-7890'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          _buildListTile(
            Icons.info_outline_rounded, 
            'Tentang AzagasPay', 
            'Versi 1.0.0',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          _buildListTile(
            Icons.security_outlined,
            'Kebijakan Privasi',
            null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          _buildListTile(
            Icons.help_outline_rounded,
            'Pusat Bantuan',
            null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String? trailing, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: trailing != null 
        ? Text(trailing, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted))
        : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GradientButton(
      label: 'Keluar Akun',
      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
      onTap: () => _onLogout(context),
    );
  }
}
