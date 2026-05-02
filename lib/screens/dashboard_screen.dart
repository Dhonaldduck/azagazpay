// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/menu_item.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../services/cart_provider.dart';
import '../widgets/common_widgets.dart';
import '../services/student_service.dart';
import 'nfc_tap_screen.dart';
import 'student_topup_request_screen.dart';
import 'student_transfer_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().fetchMenu();
      _refreshBalance();
    });
  }

  Future<void> _refreshBalance() async {
    if (!mounted) return;
    try {
      final student = await StudentService.instance.getProfile();
      if (mounted) context.read<AuthProvider>().updateBalance(student.balance);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, CartProvider, MenuProvider>(
      builder: (context, auth, cart, menu, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(children: [
            _buildHeader(auth, cart),
            _buildCategoryBar(menu),
            Expanded(child: _buildMenuGrid(menu, cart)),
          ]),
          bottomSheet: cart.hasItems
              ? _buildCheckoutBar(cart, context)
              : null,
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(AuthProvider auth, CartProvider cart) {
    final student = auth.student;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Menu Kantin',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70)),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Saldo',
                    style: GoogleFonts.poppins(fontSize: 15, color: Colors.white60)),
                  Text(student?.formattedBalance ?? 'Rp 0',
                    style: GoogleFonts.poppins(
                      fontSize: 25, fontWeight: FontWeight.w800,
                      color: Colors.white)),
                ]),
              ],
            ),
            const SizedBox(height: 10),
                        Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Halo, ${student?.name.split(' ').first ?? ''} 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: Colors.white)),
                const SizedBox(),
              ],
            ),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: _headerActionBtn(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Top-up',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StudentTopupRequestScreen()),
                  ).then((_) { if (mounted) _refreshBalance(); }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _headerActionBtn(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transfer',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StudentTransferScreen()),
                  ).then((_) { if (mounted) _refreshBalance(); }),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _buildNfcCard(student?.displayCard ?? '**** **** **** ????'),
          ]),
        ),
      ),
    );
  }

  Widget _headerActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3), width: 1.2)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(label,
            style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: Colors.white)),
        ],
      ),
    ),
  );

  Widget _buildNfcCard(String cardDisplay) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5)),
    child: Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(9)),
        child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kartu NFC',
            style: GoogleFonts.poppins(fontSize: 9, color: Colors.white60)),
          Text(cardDisplay,
            style: GoogleFonts.poppins(
              fontSize: 11, color: Colors.white,
              fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        ],
      )),
      StatusChip.active(),
    ]),
  );

  // ── Category filter ───────────────────────────────────────────
  Widget _buildCategoryBar(MenuProvider menu) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: menu.categories.map((cat) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CategoryChip(
            label: cat,
            isSelected: menu.selected == cat,
            onTap: () => menu.setCategory(cat),
          ),
        )).toList(),
      ),
    ),
  );

  // ── Menu grid ─────────────────────────────────────────────────
  Widget _buildMenuGrid(MenuProvider menu, CartProvider cart) {
    if (menu.isLoading) {
      return const Center(child: CircularProgressIndicator(
        color: AppColors.primary));
    }
    if (menu.status == MenuStatus.error) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(menu.error ?? 'Gagal memuat menu',
            style: GoogleFonts.poppins(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Coba Lagi', width: 140,
            onTap: () => menu.fetchMenu()),
        ],
      ));
    }
    if (menu.items.isEmpty) {
      return Center(child: Text('Menu tidak tersedia',
        style: GoogleFonts.poppins(color: AppColors.textMuted)));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 0.88),
      itemCount: menu.items.length,
      itemBuilder: (_, i) => _menuCard(menu.items[i], cart),
    );
  }

  Widget _menuCard(MenuItem item, CartProvider cart) {
    final qty = cart.quantityOf(item.id);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(item.emoji,
            style: const TextStyle(fontSize: 20)))),
        const SizedBox(height: 8),
        Text(item.name,
          style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
          maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('Stok: ${item.stock}',
          style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textMuted)),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item.formattedPrice,
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: AppColors.primary)),
            qty == 0
                ? _addBtn(item, cart)
                : _qtyCtrl(item, cart, qty),
          ],
        ),
      ]),
    );
  }

  Widget _addBtn(MenuItem item, CartProvider cart) => GestureDetector(
    onTap: () => cart.addItem(item),
    child: Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.add, color: Colors.white, size: 16)),
  );

  Widget _qtyCtrl(MenuItem item, CartProvider cart, int qty) => Row(children: [
    GestureDetector(
      onTap: () => cart.removeItem(item.id),
      child: Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderLight, width: 1)),
        child: const Icon(Icons.remove, color: AppColors.primary, size: 13))),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text('$qty',
        style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary))),
    GestureDetector(
      onTap: () => cart.addItem(item),
      child: Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.add, color: Colors.white, size: 13))),
  ]);

  // ── Checkout bar ──────────────────────────────────────────────
  Widget _buildCheckoutBar(CartProvider cart, BuildContext ctx) => Container(
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      boxShadow: [BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.3),
        blurRadius: 16, offset: const Offset(0, -4))]),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(7)),
            child: Center(child: Text('${cart.itemCount}',
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: Colors.white)))),
          const SizedBox(width: 8),
          Text('${cart.itemCount} item dipilih',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => const NfcTapScreen(isLoginMode: false))),
            child: Row(children: [
              Text('Bayar ${cart.formattedTotal}',
                style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 14),
            ]),
          ),
        ]),
      ),
    ),
  );
}
