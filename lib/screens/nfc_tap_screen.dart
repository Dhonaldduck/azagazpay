// lib/screens/nfc_tap_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/cart_provider.dart';
import '../services/nfc_service.dart';
import '../widgets/common_widgets.dart';
import 'payment_success_screen.dart';
import 'main_navigation_screen.dart';

class NfcTapScreen extends StatefulWidget {
  final bool isLoginMode;
  const NfcTapScreen({super.key, this.isLoginMode = false});

  @override
  State<NfcTapScreen> createState() => _NfcTapScreenState();
}

class _NfcTapScreenState extends State<NfcTapScreen>
    with SingleTickerProviderStateMixin {
  static const bool _simulateNfc = true; // Diaktifkan untuk testing di emulator

  late final NfcService _nfc;
  late final AnimationController _pulseCtrl;
  bool _isDone = false;
  bool _showSimulate = false;
  Timer? _simulateTimer;

  @override
  void initState() {
    super.initState();
    _nfc = NfcService();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _startScan();
    
    // Tampilkan tombol simulasi setelah 5 detik jika belum selesai
    _simulateTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isDone) {
        setState(() => _showSimulate = true);
      }
    });
  }

  @override
  void dispose() {
    _simulateTimer?.cancel();
    _pulseCtrl.dispose();
    _nfc.cancelScan();
    _nfc.dispose();
    super.dispose();
  }

  void _startScan() async {
    final uid = _simulateNfc
        ? await _nfc.simulateScan(delaySeconds: 3)
        : await _nfc.startScan();
    if (!mounted || _isDone) return;
    _isDone = true;

    if (uid == null) {
      _showError(_nfc.errorMessage ?? 'Scan dibatalkan');
      return;
    }

    if (widget.isLoginMode) {
      await _handleNfcLogin(uid);
    } else {
      await _handleNfcPayment(uid);
    }
  }

  void _onManualSimulate() async {
    if (_isDone) return;
    _simulateTimer?.cancel();
    setState(() => _showSimulate = false);
    
    final uid = await _nfc.simulateScan(delaySeconds: 1);
    if (!mounted || _isDone) return;
    _isDone = true;

    if (uid != null) {
      if (widget.isLoginMode) {
        await _handleNfcLogin(uid);
      } else {
        await _handleNfcPayment(uid);
      }
    }
  }

  // ── NFC Login ────────────────────────────────────────────────
  Future<void> _handleNfcLogin(String uid) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithNfc(uid);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (_) => false);
    } else {
      _showError(auth.errorMessage ?? 'Kartu tidak dikenali');
    }
  }

  // ── NFC Payment ──────────────────────────────────────────────
  Future<void> _handleNfcPayment(String uid) async {
    final cart = context.read<CartProvider>();
    final tx = await cart.processPayment(uid: uid);
    if (!mounted) return;

    if (tx != null) {
      // Update saldo di AuthProvider
      context.read<AuthProvider>().updateBalance(tx.balanceAfter);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(transaction: tx)));
    } else {
      _showError(cart.paymentError ?? 'Pembayaran gagal');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF),
                     Color(0xFFEDE9FE), Color(0xFFF3E8FF)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(child: Column(children: [
          _buildAppBar(),
          if (!widget.isLoginMode) _buildOrderSummary(cart),
          const Spacer(),
          _buildNfcAnimation(),
          const SizedBox(height: 24),
          _buildInstruction(),
          const Spacer(),
        ])),
      ),
    );
  }

  Widget _buildAppBar() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textSecondary, size: 16))),
      const SizedBox(width: 12),
      Text(
        widget.isLoginMode ? 'Masuk dengan NFC' : 'Pembayaran NFC',
        style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary)),
    ]),
  );

  Widget _buildOrderSummary(CartProvider cart) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Row(children: [
          Text('RINGKASAN PESANAN',
            style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 0.5, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 10),
        ...cart.items.values.map((ci) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${ci.quantity}x ${ci.menuItem.name}',
                style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
              Text(ci.formattedSubtotal,
                style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
            ]),
        )),
        const Divider(color: AppColors.border, thickness: 1, height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total', style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary)),
          Text(cart.formattedTotal, style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w800,
            color: AppColors.primary)),
        ]),
      ]),
    ),
  );

  Widget _buildNfcAnimation() {
    final isProcessing = context.watch<CartProvider>().isProcessing;
    return NfcRippleWidget(
      size: 200,
      color: isProcessing ? AppColors.success : AppColors.primary,
      child: const FloatingNfcCard(iconSize: 44),
    );
  }

  Widget _buildInstruction() {
    final isProcessing = context.watch<CartProvider>().isProcessing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        Text(
          isProcessing
              ? 'Memproses...'
              : widget.isLoginMode
                  ? 'Tempelkan Kartu Siswa'
                  : 'Tempelkan Kartu NFC',
          style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary),
          textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          isProcessing
              ? 'Sedang memproses transaksi, jangan pindahkan kartu'
              : widget.isLoginMode
                  ? 'Dekatkan kartu siswa ke bagian tengah layar'
                  : 'Dekatkan kartu siswa ke tengah layar untuk pembayaran',
          style: GoogleFonts.poppins(
            fontSize: 12, color: AppColors.textMuted, height: 1.5),
          textAlign: TextAlign.center),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Opacity(
            opacity: 0.7 + _pulseCtrl.value * 0.3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.25), width: 1.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.primary)),
                const SizedBox(width: 8),
                Text('NFC Aktif · Siap Membaca Kartu',
                  style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
              ]),
            ),
          ),
        ),
        if (_showSimulate) ...[
          const SizedBox(height: 20),
          TextButton(
            onPressed: _onManualSimulate,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Simulasi Tap Kartu', 
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ]),
    );
  }
}
