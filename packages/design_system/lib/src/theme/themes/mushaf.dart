import 'package:flutter/widgets.dart';

import '../app_theme.dart';
import '../palette.dart';

/// Default free theme: warm paper, near-black ink and one deep gold by day;
/// AMOLED ink and lamp gold by night (Qiyam).
const mushafTheme = AppTheme(
  id: 'mushaf',
  name: 'Mushaf',
  light: Palette(
    brightness: Brightness.light,
    surfacePage: Color(0xFFFAF8F4),
    surfaceRaised: Color(0xFFFFFDFA),
    inkAyah: Color(0xFF1C1B19),
    inkPrimary: Color(0xFF1C1B19),
    inkSecondary: Color(0xFF6B675F),
    inkMuted: Color(0xFF77726A),
    accent: Color(0xFF8A6A2F),
    onAccent: Color(0xFFFAF8F4),
    brand: Color(0xFF8DA083),
    brandSoft: Color(0xFFEFEBE4),
    border: Color(0xFFECE8E1),
    glassTint: Color(0x33FFFFFF),
    glassEdge: Color(0xCCFFFFFF),
    glassShade: Color(0x331C1B19),
    ribbonTilawah: Color(0xFF8A6A2F),
    ribbonHafalan: Color(0xFF8DA083),
    ribbonMurajaah: Color(0xFFA0715A),
  ),
  dark: Palette(
    brightness: Brightness.dark,
    surfacePage: Color(0xFF0E0F0D),
    surfaceRaised: Color(0xFF1E201C),
    inkAyah: Color(0xFFE9E2D0),
    inkPrimary: Color(0xFFE9E2D0),
    inkSecondary: Color(0xFFB4AD9C),
    inkMuted: Color(0xFF8C8676),
    accent: Color(0xFFC9A25A),
    onAccent: Color(0xFF0E0F0D),
    brand: Color(0xFF8DA083),
    brandSoft: Color(0xFF2A2B27),
    border: Color(0xFF262722),
    glassTint: Color(0x1AC9A25A),
    glassEdge: Color(0x5CE9E2D0),
    glassShade: Color(0x29E9E2D0),
    ribbonTilawah: Color(0xFFC9A25A),
    ribbonHafalan: Color(0xFF8DA083),
    ribbonMurajaah: Color(0xFFB98468),
  ),
);
