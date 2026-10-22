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
    final content = Padding(padding: padding, child: child);
    final grouped = BackdropGroup.of(context) != null;
    final blur = ImageFilter.blur(sigmaX: 16, sigmaY: 16);
    final frostedFill = DecoratedBox(
      decoration: _decoration(context, tint),
      child: content,
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
        decoration: _decoration(
          context,
          AppColors.surfaceRaised.resolve(context),
        ),
        child: content,
      ),
    };
  }

  ShapeDecoration _decoration(BuildContext context, Color fill) {
    return ShapeDecoration(
      color: fill,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: AppColors.glassEdge.resolve(context),
          width: 0.5,
        ),
      ),
    );
  }
}
