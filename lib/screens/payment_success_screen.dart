// lib/screens/payment_success_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final Transaction transaction;
  const PaymentSuccessScreen({super.key, required this.transaction});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final AnimationController _contentCtrl;
  late final AnimationController _confettiCtrl;
  late final Animation<double> _checkScale;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  final _confetti = <_ConfettiPiece>[];

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = CurvedAnimation(
      parent: _checkCtrl, curve: Curves.elasticOut);

    _contentCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _contentFade = CurvedAnimation(
      parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
          parent: _contentCtrl, curve: Curves.easeOutCubic));

    _confettiCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

    const colors = [
      Color(0xFFF59E0B), Color(0xFF6366F1), Color(0xFFEC4899),
      Color(0xFF10B981), Color(0xFFA855F7), Color(0xFF38BDF8),
    ];
    for (int i = 0; i < 22; i++) {
      _confetti.add(_ConfettiPiece(
        startX: (i * 13.0) % 300,
        delay: i * 130,
        color: colors[i % colors.length],
        size: 6.0 + (i % 3) * 3,
        isCircle: i % 3 == 0,
      ));
    }

    Future.delayed(const Duration(milliseconds: 100), () => _checkCtrl.forward());
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        AnimatedBuilder(
          animation: _confettiCtrl,
          builder: (_, __) => CustomPaint(
            painter: _ConfettiPainter(
              pieces: _confetti, progress: _confettiCtrl.value),
            size: Size(MediaQuery.of(context).size.width, 120))),

        SafeArea(
          child: FadeTransition(
            opacity: _contentFade,
            child: SlideTransition(
              position: _contentSlide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(children: [
                  const SizedBox(height: 16),
                  ScaleTransition(scale: _checkScale, child: _checkmark()),
                  const SizedBox(height: 14),
                  Text('Pembayaran Berhasil!',
                    style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Transaksi telah dikonfirmasi',
                    style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  _totalCard(tx),
                  const SizedBox(height: 12),
                  _detailCard(tx),
                  const SizedBox(height: 16),
                  _actions(context),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _checkmark() => Container(
    width: 74, height: 74,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF10B981)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(
        color: const Color(0xFF10B981).withOpacity(0.38),
        blurRadius: 24, offset: const Offset(0, 10))]),
    child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
  );

  Widget _totalCard(Transaction tx) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
        color: AppColors.primary.withOpacity(0.3),
        blurRadius: 22, offset: const Offset(0, 8))]),
    child: Column(children: [
      Text('Total Dibayar',
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
      const SizedBox(height: 4),
      Text(tx.formattedTotal,
        style: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 4),
      Text('via Kartu NFC · Berhasil',
        style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
      const Divider(color: Colors.white24, height: 20, thickness: 0.5),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          const Icon(Icons.access_time_rounded,
            color: Colors.white54, size: 14),
          const SizedBox(width: 5),
          Text('Waktu Transaksi',
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
        ]),
        Text(_formatTime(tx.completedAt ?? tx.createdAt),
          style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.9))),
      ]),
    ]),
  );

  Widget _detailCard(Transaction tx) => AppCard(
    padding: const EdgeInsets.all(14),
    color: const Color(0xFFF8FAFC),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('DETAIL PESANAN',
        style: GoogleFonts.poppins(
          fontSize: 9, fontWeight: FontWeight.w700,
          letterSpacing: 0.5, color: AppColors.textMuted)),
      const SizedBox(height: 10),
      ...tx.items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${item.quantity}x ${item.name}',
              style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary)),
            Text(item.formattedSubtotal,
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          ]),
      )),
      const Divider(color: AppColors.border, height: 14, thickness: 0.5),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Saldo Tersisa',
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
        Text(tx.formattedBalanceAfter,
          style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w800,
            color: AppColors.primary)),
      ]),
    ]),
  );

  Widget _actions(BuildContext context) => Row(children: [
    Expanded(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.receipt_long_outlined, size: 16),
        label: Text('Simpan Nota',
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          foregroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12))),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(flex: 2,
      child: GradientButton(
        label: 'Pesan Lagi',
        icon: const Icon(Icons.shopping_bag_outlined,
          color: Colors.white, size: 16),
        onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (_) => false),
      )),
  ]);

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return 'Hari ini · $h:$m WIB';
  }
}

// ── Confetti ──────────────────────────────────────────────────
class _ConfettiPiece {
  final double startX;
  final int delay;
  final Color color;
  final double size;
  final bool isCircle;
  const _ConfettiPiece({
    required this.startX, required this.delay,
    required this.color, required this.size, required this.isCircle});
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;
  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final dp = (progress - p.delay / 3000).clamp(0.0, 1.0);
      if (dp <= 0) continue;
      final y = dp * size.height * 1.5;
      final x = p.startX + dp * 20;
      final opacity = (1 - dp * 0.7).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(dp * 3.14 * 2);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
