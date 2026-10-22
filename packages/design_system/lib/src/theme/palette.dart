import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../tokens/color_tokens.dart';

/// Concrete colors for one brightness of one theme.
///
/// Every field is required, so a theme cannot ship with a missing color.
@immutable
class Palette {
  const Palette({
    required this.brightness,
    required this.surfacePage,
    required this.surfaceRaised,
    required this.inkAyah,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkMuted,
    required this.accent,
    required this.onAccent,
    required this.brand,
    required this.brandSoft,
    required this.border,
    required this.glassTint,
    required this.glassEdge,
    required this.ribbonTilawah,
    required this.ribbonHafalan,
    required this.ribbonMurajaah,
  });

  final Brightness brightness;
  final Color surfacePage;
  final Color surfaceRaised;
  final Color inkAyah;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color inkMuted;
  final Color accent;
  final Color onAccent;
  final Color brand;
  final Color brandSoft;
  final Color border;
  final Color glassTint;
  final Color glassEdge;
  final Color ribbonTilawah;
  final Color ribbonHafalan;
  final Color ribbonMurajaah;

  Map<ColorToken, Color> get tokens => {
    AppColors.surfacePage: surfacePage,
    AppColors.surfaceRaised: surfaceRaised,
    AppColors.inkAyah: inkAyah,
    AppColors.inkPrimary: inkPrimary,
    AppColors.inkSecondary: inkSecondary,
    AppColors.inkMuted: inkMuted,
    AppColors.accent: accent,
    AppColors.onAccent: onAccent,
    AppColors.brand: brand,
    AppColors.brandSoft: brandSoft,
    AppColors.border: border,
    AppColors.glassTint: glassTint,
    AppColors.glassEdge: glassEdge,
    AppColors.ribbonTilawah: ribbonTilawah,
    AppColors.ribbonHafalan: ribbonHafalan,
    AppColors.ribbonMurajaah: ribbonMurajaah,
  };
}
