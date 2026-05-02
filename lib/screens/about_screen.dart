// lib/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Tentang Aplikasi',
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppHeader(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('About Developers'),
                  const SizedBox(height: 12),
                  _buildDeveloperInfo(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Why We Made This App'),
                  const SizedBox(height: 12),
                  _buildWhyThisAppCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildAppHeader() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AzagasPay',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Versi 1.0.0',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Kantin Digital',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.school_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'This app was developed by students from SMPI Al-Azhar 23 Semarang. The development team consists of Muhammad Raditya Aryo Tejo and Rikza Abiyoga.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyThisAppCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _buildWhyItem(
                  Icons.speed_rounded,
                  'Why This App?',
                  'School payments are part of students daily activities, but they can sometimes be inconvenient, slow, or require carrying cash. '
                  'Many students find it challenging to make quick and secure transactions within the school environment. '
                  'This app was created to make that process easier. '
                  'AZAGAS PAY allows students to perform payments quickly and efficiently using NFC (Near Field Communication) technology. '
                  'By simply tapping their card or device, users can complete transactions in seconds without the need for cash or complicated steps. '
                  'The app also focuses on convenience, security, and efficiency. '
                  'It provides a simple and user-friendly system that helps students manage their daily transactions smoothly while reducing the risk of losing money or making errors in payments. '
                  'AZAGAS PAY is designed specifically for students in the school environment, aiming to support a modern, cashless system that is practical for everyday use. '
                  'It is not only a payment tool, but also a step toward building smarter and more efficient habits in managing transactions within the school community.',
                ),
          const Divider(height: 24, thickness: 1, color: AppColors.border),

          _buildWhyItem(
            Icons.speed_rounded,
            'Efisiensi Transaksi',
            'Mengurangi antrean di kantin dengan sistem pembayaran tap NFC yang instan, menghilangkan kebutuhan untuk mencari uang kembalian.',
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.border),
          _buildWhyItem(
            Icons.security_rounded,
            'Keamanan & Higienitas',
            'Sistem cashless meminimalkan penggunaan uang fisik yang kotor di area makanan dan mencegah risiko kehilangan uang saku bagi siswa.',
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.border),
          _buildWhyItem(
            Icons.analytics_outlined,
            'Transparansi Riwayat',
            'Siswa dan sekolah dapat memantau riwayat transaksi secara real-time untuk manajemen pengeluaran yang lebih baik.',
          ),
        ],
      ),
    );
  }

  Widget _buildWhyItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
