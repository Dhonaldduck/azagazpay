import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// GRADIENT BUTTON — tombol utama dengan gradient indigo-violet
// ─────────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final Widget? icon;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.width,
    this.height = 48,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// APP CARD — kartu putih dengan shadow lembut
// ─────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.color,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ?? Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATUS CHIP — Aktif/Online/Offline badge
// ─────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  factory StatusChip.active() => const StatusChip(
    label: 'Aktif', color: AppColors.success,
  );

  factory StatusChip.online() => const StatusChip(
    label: 'Online', color: AppColors.success,
  );

  factory StatusChip.offline() => StatusChip(
    label: 'Offline',
    color: Colors.grey.shade200,
    textColor: Colors.grey.shade500,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CATEGORY CHIP — filter kategori menu (Semua/Makanan/Minuman)
// ─────────────────────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10, offset: const Offset(0, 3),
                )]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NFC RIPPLE WIDGET — animasi gelombang radar NFC
// ─────────────────────────────────────────────────────────────
class NfcRippleWidget extends StatefulWidget {
  final double size;
  final Color color;
  final Widget child;

  const NfcRippleWidget({
    super.key,
    this.size = 180,
    this.color = AppColors.primary,
    required this.child,
  });

  @override
  State<NfcRippleWidget> createState() => _NfcRippleWidgetState();
}

class _NfcRippleWidgetState extends State<NfcRippleWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    // 3 cincin ripple dengan delay bertahap
    _controllers = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      );
      Future.delayed(Duration(milliseconds: i * 700), () {
        if (mounted) ctrl.repeat();
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple rings
          ..._controllers.map((ctrl) => AnimatedBuilder(
            animation: ctrl,
            builder: (_, __) => Opacity(
              opacity: (1 - ctrl.value).clamp(0, 1),
              child: Transform.scale(
                scale: 0.4 + ctrl.value * 1.6,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          )),
          // Center content
          widget.child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FLOATING NFC CARD ICON — animasi kartu melayang-layang
// ─────────────────────────────────────────────────────────────
class FloatingNfcCard extends StatefulWidget {
  final double iconSize;
  const FloatingNfcCard({super.key, this.iconSize = 44});

  @override
  State<FloatingNfcCard> createState() => _FloatingNfcCardState();
}

class _FloatingNfcCardState extends State<FloatingNfcCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: Container(
        width: widget.iconSize * 2,
        height: widget.iconSize * 2,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(widget.iconSize * 0.52),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.42),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          Icons.credit_card_rounded,
          size: widget.iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FORMAT CURRENCY HELPER
// ─────────────────────────────────────────────────────────────
String formatRupiah(int amount) {
  final formatted = amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return 'Rp $formatted';
}
