// lib/core/theme/neon_theme.dart
// Shared neon effects system for FROGIO app
// Every profile (citizen, inspector, admin, vehicles) uses these.

import 'dart:math';
import 'package:flutter/material.dart';

/// ─── Color palette ────────────────────────────────────────────────────────
class NeonColors {
  // Citizen / SOS palette
  static const green = Color(0xFF00FF88);
  static const red   = Color(0xFFFF2D55);
  // Inspector palette
  static const cyan  = Color(0xFF00D4FF);
  static const blue  = Color(0xFF0088FF);
  // Admin palette
  static const gold  = Color(0xFFFFD700);
  static const amber = Color(0xFFFFAA00);
  // Vehicles palette
  static const purple = Color(0xFFBF5FFF);
  static const violet = Color(0xFF7C3AED);
  // Shared
  static const white  = Color(0xFFE8F4FF);
}

/// ─── Background gradients ─────────────────────────────────────────────────
class NeonBg {
  static const dark          = Color(0xFF0A0A0F);
  static const darkSurface   = Color(0xFF0F0F18);
  static const darkCard      = Color(0xFF14141F);
  static const darkCardLight = Color(0xFF1A1A28);

  static LinearGradient page({Color accent = NeonColors.green}) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      accent.withValues(alpha: 0.08),
      dark,
      darkSurface,
    ],
    stops: const [0.0, 0.3, 1.0],
  );

  static LinearGradient hero({
    required Color accent,
    bool inverted = false,
  }) => LinearGradient(
    colors: inverted
        ? [darkCard, accent.withValues(alpha: 0.06), darkCard]
        : [accent.withValues(alpha: 0.04), darkCard, darkCard],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// ─── Glow helpers ─────────────────────────────────────────────────────────
List<BoxShadow> neonGlow(Color color, {double intensity = 1.0}) => [
  BoxShadow(
    color: color.withValues(alpha: 0.55 * intensity),
    blurRadius: 16 * intensity,
    spreadRadius: 1,
  ),
  BoxShadow(
    color: color.withValues(alpha: 0.25 * intensity),
    blurRadius: 32 * intensity,
    spreadRadius: 4,
  ),
];

List<Shadow> neonTextShadow(Color color, {double intensity = 1.0}) => [
  Shadow(color: color.withValues(alpha: 0.9 * intensity), blurRadius: 10 * intensity),
  Shadow(color: color.withValues(alpha: 0.5 * intensity), blurRadius: 24 * intensity),
];

Border neonBorder(Color color, {double alpha = 0.5, double width = 1.0}) =>
    Border.all(color: color.withValues(alpha: alpha), width: width);

/// ─── NeonCard ─────────────────────────────────────────────────────────────
/// Pulsing neon-border dark card.  Handles its own AnimationController.
class NeonCard extends StatefulWidget {
  final Widget child;
  final Color accent;
  final EdgeInsets padding;
  final double borderRadius;
  final double? width;
  final VoidCallback? onTap;
  /// Extra decoration merged on top (e.g. a gradient background)
  final Decoration? extraDecoration;

  const NeonCard({
    super.key,
    required this.child,
    this.accent = NeonColors.green,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.width,
    this.onTap,
    this.extraDecoration,
  });

  @override
  State<NeonCard> createState() => _NeonCardState();
}

class _NeonCardState extends State<NeonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = sin(_ctrl.value * 2 * pi);
        final alpha = 0.30 + t * 0.15;
        final glow  = 0.18 + t * 0.10;
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.width,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: NeonBg.darkCard,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.accent.withValues(alpha: alpha),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: glow),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ).copyWith(
              // Allow a caller to inject a gradient
              image: (widget.extraDecoration as BoxDecoration?)?.image,
              gradient: (widget.extraDecoration as BoxDecoration?)?.gradient,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// ─── NeonHeader ───────────────────────────────────────────────────────────
/// Full-width dark header with animated neon accent line at the bottom.
class NeonHeader extends StatefulWidget {
  final Widget child;
  final Color accent;
  final double lineHeight;

  const NeonHeader({
    super.key,
    required this.child,
    this.accent = NeonColors.green,
    this.lineHeight = 1.5,
  });

  @override
  State<NeonHeader> createState() => _NeonHeaderState();
}

class _NeonHeaderState extends State<NeonHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = sin(_ctrl.value * 2 * pi);
        return Container(
          decoration: BoxDecoration(
            color: NeonBg.darkCard,
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.12 + t * 0.06),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              child!,
              Container(
                height: widget.lineHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      widget.accent.withValues(alpha: 0.6 + t * 0.3),
                      widget.accent,
                      widget.accent.withValues(alpha: 0.6 + t * 0.3),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.4 + t * 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// ─── NeonButton ───────────────────────────────────────────────────────────
/// Filled glowing button.
class NeonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color accent;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final double borderRadius;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.accent = NeonColors.green,
    this.onPressed,
    this.fullWidth = false,
    this.borderRadius = 12,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  bool _pressed = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = sin(_ctrl.value * 2 * pi);
        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onPressed?.call();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: widget.fullWidth ? double.infinity : null,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.accent.withValues(alpha: 0.85),
                    widget.accent,
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.50 + t * 0.20),
                    blurRadius: 18 + t * 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.black87, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ─── NeonBadge ────────────────────────────────────────────────────────────
/// Small glowing count badge.
class NeonBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const NeonBadge({super.key, required this.label, this.accent = NeonColors.red});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 8)],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          shadows: neonTextShadow(accent, intensity: 0.6),
        ),
      ),
    );
  }
}

/// ─── NeonDivider ──────────────────────────────────────────────────────────
class NeonDivider extends StatelessWidget {
  final Color accent;
  final double thickness;

  const NeonDivider({super.key, this.accent = NeonColors.green, this.thickness = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: thickness,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, accent.withValues(alpha: 0.5), Colors.transparent],
        ),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 6)],
      ),
    );
  }
}

/// ─── NeonStatCard ─────────────────────────────────────────────────────────
/// Small stat tile with neon icon + count.
class NeonStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const NeonStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accent = NeonColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      accent: accent,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: neonGlow(accent, intensity: 0.5),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              shadows: neonTextShadow(accent, intensity: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF888899), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// ─── NeonListTile ─────────────────────────────────────────────────────────
class NeonListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final Widget? trailing;
  final VoidCallback? onTap;

  const NeonListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent = NeonColors.cyan,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: NeonBg.darkCardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFDDDDEE),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(color: Color(0xFF777788), fontSize: 12),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// ─── NeonAppBar ───────────────────────────────────────────────────────────
/// Standard dark AppBar with neon bottom accent line.
PreferredSizeWidget neonAppBar({
  required String title,
  Color accent = NeonColors.green,
  List<Widget>? actions,
  Widget? leading,
  bool showBackButton = true,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight + 2),
    child: _NeonAppBarWidget(
      title: title,
      accent: accent,
      actions: actions,
      leading: leading,
      showBackButton: showBackButton,
    ),
  );
}

class _NeonAppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Color accent;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  const _NeonAppBarWidget({
    required this.title,
    required this.accent,
    this.actions,
    this.leading,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2);

  @override
  State<_NeonAppBarWidget> createState() => _NeonAppBarWidgetState();
}

class _NeonAppBarWidgetState extends State<_NeonAppBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = sin(_ctrl.value * 2 * pi);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: NeonBg.darkCard,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: widget.showBackButton,
              leading: widget.leading,
              title: Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  shadows: neonTextShadow(widget.accent, intensity: 0.4),
                ),
              ),
              iconTheme: IconThemeData(color: widget.accent),
              actions: widget.actions,
            ),
            Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    widget.accent.withValues(alpha: 0.5 + t * 0.3),
                    widget.accent,
                    widget.accent.withValues(alpha: 0.5 + t * 0.3),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.3 + t * 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
