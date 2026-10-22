import 'package:flutter/painting.dart';
import 'package:mix/mix.dart';

/// Font families. Arabic and Latin are set apart on purpose: mushaf text needs
/// its own size and line height.
///
/// Fonts are not bundled yet; until they are, Flutter falls back to the
/// platform font for each family.
abstract final class AppFonts {
  static const arabic = 'UthmanicHafs';
  static const serif = 'Newsreader';
  static const sans = 'Inter';
}

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
    ayah: TextStyle(fontFamily: AppFonts.arabic, fontSize: 26, height: 2.1),
    translation: TextStyle(
      fontFamily: AppFonts.serif,
      fontSize: 15,
      height: 1.6,
    ),
    title: TextStyle(
      fontFamily: AppFonts.serif,
      fontSize: 22,
      height: 1.3,
      fontWeight: FontWeight.w500,
    ),
    body: TextStyle(fontFamily: AppFonts.sans, fontSize: 15, height: 1.5),
    label: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 13,
      height: 1.3,
      fontWeight: FontWeight.w500,
    ),
    caption: TextStyle(fontFamily: AppFonts.sans, fontSize: 12, height: 1.4),
    counter: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 56,
      height: 1,
      fontWeight: FontWeight.w500,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
  };
}
