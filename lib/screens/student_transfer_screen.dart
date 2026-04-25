// lib/screens/student_transfer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/topup_service.dart';
import '../utils/app_exceptions.dart';
import '../theme/app_theme.dart';

class StudentTransferScreen extends StatefulWidget {
  const StudentTransferScreen({super.key});

  @override
  State<StudentTransferScreen> createState() => _StudentTransferScreenState();
}

class _StudentTransferScreenState extends State<StudentTransferScreen> {
  final _nisnCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  final _service    = TopupService.instance;

  bool _lookupLoading = false;
  bool _transferLoading = false;
  bool _success = false;

  Map<String, dynamic>? _receiver;
  String? _lookupError;
  String? _successMessage;

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
    _nisnCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _fmtAmount(String val) {
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

  Future<void> _onLookup() async {
    final nisn = _nisnCtrl.text.trim();
    if (nisn.isEmpty) {
      setState(() => _lookupError = 'Masukkan NISN penerima');
      return;
    }
    setState(() { _lookupLoading = true; _lookupError = null; _receiver = null; });
    try {
      final data = await _service.lookupStudent(nisn);
      if (!mounted) return;
      setState(() { _lookupLoading = false; _receiver = data; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _lookupLoading = false; _lookupError = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _lookupLoading = false; _lookupError = 'Gagal mencari siswa'; });
    }
  }

  Future<void> _onTransfer() async {
    if (_receiver == null) return;
    final digits = _amountCtrl.text.replaceAll('.', '');
    final amount = int.tryParse(digits);
    if (amount == null || amount < 1000) {
      _showSnack('Masukkan nominal minimal Rp 1.000', isError: true);
      return;
    }

    final balance = context.read<AuthProvider>().student?.balance ?? 0;
    if (amount > balance) {
      _showSnack('Saldo tidak mencukupi', isError: true);
      return;
    }

    final receiverName = _receiver!['name'] as String;
    final fmtAmount = amount.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi Transfer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow('Penerima', receiverName),
            const SizedBox(height: 8),
            _confirmRow('Kelas', _receiver!['studentClass'] as String? ?? '-'),
            const SizedBox(height: 8),
            _confirmRow('Jumlah', 'Rp $fmtAmount'),
          ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
              style: GoogleFonts.poppins(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
            child: Text('Transfer',
              style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _transferLoading = true);
    try {
      final result = await _service.transferBalance(
        receiverNisn: _nisnCtrl.text.trim(),
        amount: amount,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      final newBalance = result['newBalance'] as int?;
      if (newBalance != null && mounted) {
        context.read<AuthProvider>().updateBalance(newBalance);
      }
      setState(() {
        _transferLoading = false;
        _success = true;
        _successMessage =
          'Rp $fmtAmount berhasil ditransfer ke $receiverName';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _transferLoading = false);
      _showSnack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _transferLoading = false);
      _showSnack('Terjadi kesalahan, coba lagi', isError: true);
    }
  }

  Widget _confirmRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.poppins(
        fontSize: 12, color: AppColors.textMuted)),
      Text(value, style: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary)),
    ],
  );

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
    final balance =
        context.watch<AuthProvider>().student?.formattedBalance ?? 'Rp 0';
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
            Text('Transfer Saldo',
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
          const Icon(Icons.swap_horiz_rounded,
            color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Transfer saldo langsung ke sesama siswa tanpa perlu melibatkan guru.',
            style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.primary))),
        ]),
      ),
      const SizedBox(height: 20),

      // Cari penerima
      _sectionLabel('NISN PENERIMA'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 8, offset: const Offset(0, 2))]),
            child: TextField(
              controller: _nisnCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                if (_receiver != null || _lookupError != null) {
                  setState(() { _receiver = null; _lookupError = null; });
                }
              },
              decoration: InputDecoration(
                hintText: 'Masukkan NISN penerima',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding:
                  const EdgeInsets.symmetric(vertical: 14)),
              style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _lookupLoading ? null : _onLookup,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: _lookupLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : Text('Cari',
                    style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ),
      ]),

      // Hasil lookup
      if (_lookupError != null) ...[
        const SizedBox(height: 8),
        Text(_lookupError!,
          style: GoogleFonts.poppins(
            fontSize: 11, color: AppColors.error)),
      ],
      if (_receiver != null) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3), width: 1.5)),
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.success.withValues(alpha: 0.15),
              child: Text(
                (_receiver!['name'] as String).isNotEmpty
                    ? (_receiver!['name'] as String)[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  color: AppColors.success))),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_receiver!['name'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              Text(_receiver!['studentClass'] as String? ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textMuted)),
            ]),
            const Spacer(),
            const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          ]),
        ),
      ],

      const SizedBox(height: 20),

      // Nominal cepat
      _sectionLabel('NOMINAL CEPAT'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 6,
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
                  color: AppColors.primary))));
        }).toList()),
      const SizedBox(height: 16),

      // Input nominal
      _sectionLabel('JUMLAH TRANSFER'),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2))]),
        child: TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          onChanged: (v) {
            final formatted = _fmtAmount(v);
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
      ),
      const SizedBox(height: 12),

      // Catatan opsional
      _sectionLabel('CATATAN (OPSIONAL)'),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2))]),
        child: TextField(
          controller: _noteCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Contoh: bayar patungan',
            hintStyle: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textMuted),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textPrimary),
        ),
      ),
      const SizedBox(height: 24),

      // Tombol transfer
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_transferLoading || _receiver == null)
              ? null
              : _onTransfer,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14))),
          child: _transferLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : Text(
                  _receiver == null
                      ? 'Cari penerima terlebih dahulu'
                      : 'Transfer Sekarang',
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
    ]),
  );

  Widget _sectionLabel(String label) => Text(label,
    style: GoogleFonts.poppins(
      fontSize: 10, fontWeight: FontWeight.w700,
      letterSpacing: 0.5, color: AppColors.textMuted));

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
        Text('Transfer Berhasil!',
          style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(
          _successMessage ?? 'Transfer saldo berhasil dilakukan.',
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
