// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/server_config_service.dart';
import '../widgets/common_widgets.dart';
import 'guru_dashboard_screen.dart';
import 'nfc_tap_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isStudent = true;
  bool _obscurePin = true;
  final _idCtrl  = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _idCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _onRoleSwitch(bool isStudent) {
    setState(() {
      _isStudent = isStudent;
      _idCtrl.clear();
      _pinCtrl.clear();
      _obscurePin = true;
    });
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();

    if (_isStudent) {
      final ok = await auth.loginWithPin(
        nisn: _idCtrl.text.trim(),
        pin:  _pinCtrl.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        _showSnackbar(auth.errorMessage ?? 'Login gagal');
      }
    } else {
      final ok = await auth.loginWithPinGuru(
        username: _idCtrl.text.trim(),
        password: _pinCtrl.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GuruDashboardScreen()),
        );
      } else {
        _showSnackbar(auth.errorMessage ?? 'Login gagal');
      }
    }
  }

  void _onNfcLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NfcTapScreen(isLoginMode: true)),
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(children: [
                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: _buildFormCard(),
                    ),
                    if (_isStudent) ...[
                      _buildDivider(),
                      const SizedBox(height: 10),
                      _buildNfcButton(),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  int _secretTapCount = 0;

  void _onSecretTap() {
    _secretTapCount++;
    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      _showServerConfigDialog();
    }
  }

  void _showServerConfigDialog() async {
    final config = ServerConfigService.instance;
    final currentUrl = await config.getBaseUrl();
    final ctrl = TextEditingController(text: currentUrl);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pengaturan Server', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ganti URL API Backend secara dinamis.', 
              style: GoogleFonts.poppins(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://172.20.10.3:3000/api',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await config.resetToDefault();
              if (mounted) Navigator.pop(context);
              _showSnackbar('URL direset ke default');
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await config.setBaseUrl(ctrl.text.trim());
                if (mounted) Navigator.pop(context);
                _showSnackbar('Server diperbarui ke: ${ctrl.text}');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    height: 150,
    decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    child: Stack(children: [
      Positioned(top: -30, right: -30,
        child: Container(width: 140, height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1)))),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: GestureDetector(
            onTap: _onSecretTap,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withOpacity(0.38), width: 1.5),
              ),
              child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    ]),
  );

  Widget _buildFormCard() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Selamat Datang',
          style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary)),
        const SizedBox(height: 3),
        Text('Masuk ke AzagasPay untuk bertransaksi',
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 16),

        // Toggle Siswa / Guru
        _buildRoleToggle(),
        const SizedBox(height: 16),

        // ID field (NISN untuk siswa, Username untuk guru)
        _buildLabel(_isStudent ? 'ID SISWA / NISN' : 'USERNAME'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _idCtrl,
          keyboardType: _isStudent
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters: _isStudent
              ? [FilteringTextInputFormatter.digitsOnly]
              : [],
          decoration: InputDecoration(
            hintText: _isStudent ? 'Masukkan NISN' : 'Masukkan username',
            prefixIcon: Icon(
              _isStudent
                  ? Icons.person_outline_rounded
                  : Icons.badge_outlined,
              color: AppColors.textMuted, size: 20),
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? (_isStudent ? 'NISN wajib diisi' : 'Username wajib diisi')
              : null,
        ),
        const SizedBox(height: 12),

        // Password / PIN
        _buildLabel(_isStudent ? 'PIN' : 'PASSWORD'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _pinCtrl,
          obscureText: _obscurePin,
          keyboardType: _isStudent
              ? TextInputType.number
              : TextInputType.visiblePassword,
          inputFormatters: _isStudent
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ]
              : [],
          decoration: InputDecoration(
            hintText: _isStudent ? 'Masukkan PIN 6 digit' : 'Masukkan password',
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: AppColors.textMuted, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePin ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted, size: 20),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return _isStudent ? 'PIN wajib diisi' : 'Password wajib diisi';
            }
            if (_isStudent && v.trim().length < 4) return 'PIN minimal 4 digit';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Tombol masuk
        Consumer<AuthProvider>(
          builder: (_, auth, __) => GradientButton(
            label: 'Masuk Sekarang',
            onTap: _onLogin,
            isLoading: auth.isLoading,
          ),
        ),
        const SizedBox(height: 12),

        Center(child: RichText(text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
          children: [
            TextSpan(text: _isStudent ? 'Lupa PIN? ' : 'Lupa password? '),
            WidgetSpan(child: GestureDetector(
              onTap: () {},
              child: Text('Hubungi Admin',
                style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
            )),
          ],
        ))),
      ]),
    );
  }

  Widget _buildRoleToggle() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.all(3),
    child: Row(children: [
      _roleTab('Siswa', true),
      _roleTab('Guru', false),
    ]),
  );

  Widget _roleTab(String label, bool forStudent) {
    final active = _isStudent == forStudent;
    return Expanded(child: GestureDetector(
      onTap: () => _onRoleSwitch(forStudent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(label,
          style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textMuted))),
      ),
    ));
  }

  Widget _buildDivider() => Row(children: [
    const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text('atau masuk dengan NFC',
        style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted))),
    const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
  ]);

  Widget _buildNfcButton() => GestureDetector(
    onTap: _onNfcLogin,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.28), width: 1.5)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.nfc_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text('Tap Kartu NFC',
          style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: AppColors.primary)),
      ]),
    ),
  );

  Widget _buildLabel(String text) => Text(text,
    style: GoogleFonts.poppins(
      fontSize: 10, fontWeight: FontWeight.w700,
      letterSpacing: 0.5, color: AppColors.textMuted));
}
