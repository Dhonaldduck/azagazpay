// lib/screens/student_topup_request_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/topup_service.dart';
import '../utils/app_exceptions.dart';
import '../theme/app_theme.dart';

class StudentTopupRequestScreen extends StatefulWidget {
  const StudentTopupRequestScreen({super.key});

  @override
  State<StudentTopupRequestScreen> createState() =>
      _StudentTopupRequestScreenState();
}

class _StudentTopupRequestScreenState
    extends State<StudentTopupRequestScreen> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  final _service    = TopupService.instance;
  bool _loading     = false;
  bool _success     = false;

  static const _quickAmounts = [5000, 10000, 20000, 50000, 100000];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmt(String val) {
    final digits = val.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    final n = int.tryParse(digits) ?? 0;
    return n.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  void _setQuick(int amount) {
    final text = amount.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    _amountCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length));
    setState(() {});
  }

  Future<void> _onSubmit() async {
    final digits = _amountCtrl.text.replaceAll('.', '');
    final amount = int.tryParse(digits);
    if (amount == null || amount < 1000) {
      _showSnack('Masukkan nominal minimal Rp 1.000', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _service.requestTopup(
        amount: amount,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() { _loading = false; _success = true; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Terjadi kesalahan, coba lagi', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<AuthProvider>().student?.formattedBalance
        ?? 'Rp 0';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(balance),
        Expanded(child: _success ? _buildSuccess() : _buildForm()),
      ]),
    );
  }

  Widget _buildHeader(String balance) => Container(
    decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16)),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Minta Top-up',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Colors.white)),
            Text('Saldo saat ini: $balance',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
          ]),
        ]),
      ),
    ),
  );

  Widget _buildForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Info banner
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1.5)),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
            color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Permintaan top-up akan diproses oleh guru/admin sekolah.',
            style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.primary))),
        ]),
      ),
      const SizedBox(height: 20),

      // Nominal cepat
      Text('Nominal Cepat',
        style: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textMuted)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6,
        children: _quickAmounts.map((a) {
          final label = a.toString()
              .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
          return GestureDetector(
            onTap: () => _setQuick(a),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight, width: 1.5)),
              child: Text('Rp $label',
                style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.primary))),
          );
        }).toList()),
      const SizedBox(height: 16),

      // Input nominal
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NOMINAL TOP-UP',
            style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 0.5, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            onChanged: (v) {
              final formatted = _fmt(v);
              if (formatted != v) {
                _amountCtrl.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(
                    offset: formatted.length));
              }
            },
            decoration: InputDecoration(
              hintText: '0',
              prefixText: 'Rp ',
              prefixStyle: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
              hintStyle: GoogleFonts.poppins(
                fontSize: 24, color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Catatan opsional
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CATATAN (OPSIONAL)',
            style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 0.5, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Contoh: untuk bekal minggu ini',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textPrimary),
          ),
        ]),
      ),
      const SizedBox(height: 24),

      // Tombol kirim
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _onSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14))),
          child: _loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : Text('Kirim Permintaan',
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
    ]),
  );

  Widget _buildSuccess() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline_rounded,
            color: AppColors.success, size: 44)),
        const SizedBox(height: 20),
        Text('Permintaan Terkirim!',
          style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(
          'Permintaan top-up sudah diterima.\n'
          'Guru akan segera memproses pengisian saldo.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
            child: Text('Kembali ke Beranda',
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ),
  );
}
