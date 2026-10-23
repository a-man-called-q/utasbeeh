import 'package:mix/mix.dart';

/// Semantic color tokens.
///
/// Components read only these tokens, never raw hex values, so a new theme is
/// just a new [Palette]. Each [Palette] must provide a value for every entry
/// in [values].
abstract final class AppColors {
  /// Page canvas behind everything (paper by day, ink by night).
  static const surfacePage = ColorToken('surface.page');

  /// Cards and sheets that sit on the page without glass.
  static const surfaceRaised = ColorToken('surface.raised');

  /// Arabic Qur'an text. Kept separate from [inkPrimary] so themes can tune
  /// the mushaf text without touching UI text.
  static const inkAyah = ColorToken('ink.ayah');

  static const inkPrimary = ColorToken('ink.primary');
  static const inkSecondary = ColorToken('ink.secondary');
  static const inkMuted = ColorToken('ink.muted');

  /// The single "living" accent: ayah markers, ribbons, the counter number.
  static const accent = ColorToken('accent');
  static const onAccent = ColorToken('accent.on');

  /// Calm brand color for progress and selected states.
  static const brand = ColorToken('brand');
  static const brandSoft = ColorToken('brand.soft');

  static const border = ColorToken('border');

  /// Tint applied to glass surfaces so glass follows the active theme.
  static const glassTint = ColorToken('glass.tint');

  /// Upper end of the glass rim in frosted/solid modes; also colors the
  /// frosted sheen.
  static const glassEdge = ColorToken('glass.edge');

  /// Lower end of the glass rim and sheen. Dark in light palettes so glass
  /// keeps a visible edge on pale pages.
  static const glassShade = ColorToken('glass.shade');

  static const ribbonTilawah = ColorToken('ribbon.tilawah');
  static const ribbonHafalan = ColorToken('ribbon.hafalan');
  static const ribbonMurajaah = ColorToken('ribbon.murajaah');

  static const values = <ColorToken>[
    surfacePage,
    surfaceRaised,
    inkAyah,
    inkPrimary,
    inkSecondary,
    inkMuted,
    accent,
    onAccent,
    brand,
    brandSoft,
    border,
    glassTint,
    glassEdge,
    glassShade,
    ribbonTilawah,
    ribbonHafalan,
    ribbonMurajaah,
  ];
}
