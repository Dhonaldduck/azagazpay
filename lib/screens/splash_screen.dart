// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'guru_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    // Cek auth setelah animasi selesai
    Future.delayed(const Duration(milliseconds: 2200), _checkAuth);
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.checkAuth();
    if (!mounted) return;

    Widget destination;
    if (auth.isLoggedIn) {
      destination = auth.isGuru
          ? const GuruDashboardScreen()
          : const DashboardScreen();
    } else {
      destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: Stack(children: [
          Positioned(top: -60, right: -70,
            child: _circle(220, 0.08)),
          Positioned(bottom: 80, left: -60,
            child: _circle(180, 0.06)),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(scale: _scaleAnim, child: _logoIcon()),
                      const SizedBox(height: 20),
                      Text('AzagasPay',
                        style: GoogleFonts.poppins(
                          fontSize: 34, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: -0.8)),
                      const SizedBox(height: 6),
                      Text('CASHLESS · SMART · FAST',
                        style: GoogleFonts.poppins(
                          fontSize: 11, letterSpacing: 4,
                          color: Colors.white.withOpacity(0.65),
                          fontWeight: FontWeight.w500)),
                      const SizedBox(height: 36),
                      _infoCard(),
                      const SizedBox(height: 52),
                      _dots(),
                      const SizedBox(height: 30),
                      _loadingIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );

  Widget _logoIcon() => Container(
    width: 96, height: 96,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
    ),
    child: const Icon(Icons.credit_card_rounded, size: 50, color: Colors.white),
  );

  Widget _infoCard() => Container(
    width: 240,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.5),
    ),
    child: Column(children: [
      Text('Sistem Pembayaran Kantin Digital',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 4),
      Text('Tap kartu NFC · Bayar instan · Aman',
        style: GoogleFonts.poppins(
          fontSize: 10, color: Colors.white.withOpacity(0.72))),
    ]),
  );

  Widget _dots() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 24, height: 6,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      ...List.generate(2, (_) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(width: 6, height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(3))),
      )),
    ],
  );

  Widget _loadingIndicator() => SizedBox(
    width: 20, height: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: Colors.white.withOpacity(0.6),
    ),
  );
}
