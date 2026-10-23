import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../theme/app_theme_scope.dart';
import '../tokens/color_tokens.dart';
import 'glass_mode.dart';

/// The only glass widget the app uses. It renders according to the active
/// [GlassMode], so swapping the glass implementation touches this file only.
///
/// Glass belongs to the navigation layer (bars, sheets, the counter bead).
/// Keep Qur'an text off it: put content behind glass, never on top of it.
///
/// When a screen shows several glass surfaces, wrap it in a [BackdropGroup]
/// so they share one backdrop capture instead of one each.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
  });

  /// Loads glass shaders ahead of time so the first frame shows real glass
  /// instead of the fallback. Call before `runApp`.
  static Future<void> precache() => LiquidGlass.precache();

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scope = AppThemeScope.of(context);
    final tint = AppColors.glassTint.resolve(context);
    final edge = AppColors.glassEdge.resolve(context);
    final shade = AppColors.glassShade.resolve(context);
    final content = Padding(padding: padding, child: child);
    final rimmed = CustomPaint(
      foregroundPainter: _RimPainter(shape: _shape, top: edge, bottom: shade),
      child: content,
    );
    final grouped = BackdropGroup.of(context) != null;
    final blur = ImageFilter.blur(sigmaX: 24, sigmaY: 24);
    // Tint first, then a sheen: light catching the top, shade pooling at the
    // bottom. Without the shade, pale glass on a pale page reads as a flat
    // translucent chip.
    final frostedFill = DecoratedBox(
      decoration: ShapeDecoration(color: tint, shape: _shape),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.55, 1],
            colors: [
              edge.withValues(alpha: edge.a * 0.35),
              edge.withValues(alpha: 0),
              shade.withValues(alpha: shade.a * 0.5),
            ],
          ),
          shape: _shape,
        ),
        child: rimmed,
      ),
    );

    return switch (scope.glassMode) {
      GlassMode.liquid => LiquidGlass.auto(
        shape: LiquidRoundedSuperellipse(borderRadius: radius),
        useBackdropGroup: grouped,
        // Midway on the iOS Clear↔Tinted slider. Fully clear glass refracts
        // dense Arabic text so sharply that bar labels become hard to read.
        settings: LiquidGlassSettings.ios27Regular(
          brightness: scope.brightness,
          tintAmount: 0.5,
        ),
        appearance: LiquidGlassAppearance.ios27Regular(
          brightness: scope.brightness,
          tint: tint,
        ),
        child: content,
      ),
      GlassMode.frosted => ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: grouped
            ? BackdropFilter.grouped(filter: blur, child: frostedFill)
            : BackdropFilter(filter: blur, child: frostedFill),
      ),
      GlassMode.solid => DecoratedBox(
        decoration: ShapeDecoration(
          color: AppColors.surfaceRaised.resolve(context),
          shape: _shape,
        ),
        child: rimmed,
      ),
    };
  }

  RoundedSuperellipseBorder get _shape =>
      RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius));
}

/// A 1px rim that runs from [top] to [bottom], drawn just inside the shape so
/// the frosted clip doesn't cut it in half.
class _RimPainter extends CustomPainter {
  const _RimPainter({
    required this.shape,
    required this.top,
    required this.bottom,
  });

  final ShapeBorder shape;
  final Color top;
  final Color bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ).createShader(bounds);
    canvas.drawPath(shape.getOuterPath(bounds.deflate(0.5)), paint);
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.shape != shape || old.top != top || old.bottom != bottom;
}
