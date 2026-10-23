import 'package:flutter/painting.dart';
import 'package:mix/mix.dart';

/// Font families bundled with this package (see `fonts/`). Arabic and Latin
/// are set apart on purpose: mushaf text needs its own size and line height.
///
/// UI text uses the platform font (SF Pro / Roboto), so there is no sans
/// family here.
abstract final class AppFonts {
  /// Amiri Quran: full Uthmani mark coverage (ٱ, ۥ, waqf signs).
  static const arabic = 'AmiriQuran';

  /// Newsreader variable font, for titles and translations.
  static const serif = 'Newsreader';

  static const package = 'design_system';
}

/// Newsreader is variable: weight and optical size come from axes, not from
/// separate files, so set both explicitly to match the requested style.
List<FontVariation> _serifAxes(double weight, double size) => [
  FontVariation.weight(weight),
  FontVariation('opsz', size.clamp(6, 72)),
];

/// Text style tokens. Sizes and families only — color comes from color tokens
/// at the call site, so text styles stay identical across themes.
abstract final class AppText {
  static const ayah = TextStyleToken('text.ayah');
  static const translation = TextStyleToken('text.translation');
  static const title = TextStyleToken('text.title');
  static const body = TextStyleToken('text.body');
  static const label = TextStyleToken('text.label');
  static const caption = TextStyleToken('text.caption');
  static const counter = TextStyleToken('text.counter');

  static final Map<TextStyleToken, TextStyle> scale = {
    ayah: const TextStyle(
      fontFamily: AppFonts.arabic,
      package: AppFonts.package,
      fontSize: 26,
      height: 2.1,
    ),
    translation: TextStyle(
      fontFamily: AppFonts.serif,
      package: AppFonts.package,
      fontSize: 15,
      height: 1.6,
      fontVariations: _serifAxes(400, 15),
    ),
    title: TextStyle(
      fontFamily: AppFonts.serif,
      package: AppFonts.package,
      fontSize: 26,
      height: 1.25,
      fontWeight: FontWeight.w500,
      fontVariations: _serifAxes(500, 26),
    ),
    body: const TextStyle(fontSize: 15, height: 1.5),
    label: const TextStyle(
      fontSize: 13,
      height: 1.3,
      fontWeight: FontWeight.w500,
    ),
    caption: const TextStyle(fontSize: 12, height: 1.4),
    counter: const TextStyle(
      fontSize: 56,
      height: 1,
      fontWeight: FontWeight.w500,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
  };
}
