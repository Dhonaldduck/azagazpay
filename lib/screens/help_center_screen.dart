// lib/screens/help_center_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pusat Bantuan',
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
            _buildContactCard(),
            const SizedBox(height: 24),
            Text(
              'Pertanyaan Sering Diajukan (FAQ)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'Bagaimana cara bayar dengan NFC?',
              'Buka tab "Tap NFC" di aplikasi, lalu tempelkan kartu siswa Anda ke bagian belakang HP yang mendukung NFC atau ke alat pembaca di kantin.',
            ),
            _buildFaqItem(
              'Di mana saya bisa top-up saldo?',
              'Anda bisa melakukan top-up melalui kasir kantin, koperasi sekolah, atau melalui permintaan top-up di dalam aplikasi yang disetujui oleh wali kelas/guru.',
            ),
            _buildFaqItem(
              'Kartu saya hilang, apa yang harus dilakukan?',
              'Segera lapor ke admin koperasi sekolah untuk memblokir kartu lama dan menerbitkan kartu baru agar saldo Anda tetap aman.',
            ),
            _buildFaqItem(
              'Transaksi gagal tapi saldo terpotong?',
              'Jangan khawatir, sistem kami akan melakukan pengecekan otomatis. Jika saldo tidak kembali dalam 1x24 jam, silakan hubungi admin dengan membawa bukti riwayat transaksi.',
            ),
            const SizedBox(height: 32),
            _buildSupportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Butuh Bantuan Cepat?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tim support kami siap membantu masalah teknis atau kendala transaksi Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Chat Admin Koperasi'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            answer,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kontak Lainnya',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildContactListTile(Icons.email_outlined, 'Email', 'support@azagaspay.sch.id'),
        _buildContactListTile(Icons.language_rounded, 'Website', 'www.azagaspay.sch.id'),
        _buildContactListTile(Icons.location_on_outlined, 'Lokasi', 'Gedung Koperasi Siswa, Lantai 1'),
      ],
    );
  }

  Widget _buildContactListTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
              ),
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
        ],
      ),
    );
  }
}
