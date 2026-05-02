// lib/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kebijakan Privasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Pendahuluan',
              'Selamat datang di AzagasPay. Kami sangat menghargai privasi Anda dan berkomitmen untuk melindungi data pribadi Anda. Kebijakan privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi Anda saat menggunakan aplikasi kami.',
            ),
            _buildSection(
              'Informasi yang Kami Kumpulkan',
              'Kami mengumpulkan informasi terbatas yang diperlukan untuk fungsionalitas aplikasi, termasuk:\n\n• Data Identitas (Nama, NISN, Kelas)\n• Data Transaksi (Riwayat pembelian di kantin)\n• Data Saldo dan Top-up\n• Data Perangkat (untuk keamanan akses NFC)',
            ),
            _buildSection(
              'Penggunaan Informasi',
              'Informasi yang kami kumpulkan digunakan untuk:\n\n• Memproses transaksi pembayaran kantin Anda\n• Mengelola akun dan saldo digital Anda\n• Menyediakan riwayat transaksi yang akurat\n• Meningkatkan keamanan aplikasi dan mencegah kecurangan',
            ),
            _buildSection(
              'Keamanan Data',
              'Kami menggunakan enkripsi standar industri (termasuk enkripsi AES-128 untuk komunikasi kartu NFC) untuk melindungi data Anda. Data pribadi Anda disimpan secara aman di server kami dan tidak akan dibagikan kepada pihak ketiga tanpa izin Anda, kecuali diwajibkan oleh hukum.',
            ),
            _buildSection(
              'Penyimpanan Data',
              'Kami hanya akan menyimpan data pribadi Anda selama diperlukan untuk memenuhi tujuan pengumpulan data tersebut, termasuk untuk memenuhi persyaratan hukum, akuntansi, atau pelaporan.',
            ),
            _buildSection(
              'Hubungi Kami',
              'Jika Anda memiliki pertanyaan tentang kebijakan privasi ini atau penggunaan data Anda, silakan hubungi admin sekolah melalui bagian Pusat Bantuan.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Terakhir diperbarui: 1 Mei 2026',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
