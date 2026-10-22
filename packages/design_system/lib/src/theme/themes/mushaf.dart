import 'package:flutter/widgets.dart';

import '../app_theme.dart';
import '../palette.dart';

/// Default free theme: warm paper and sage by day, AMOLED ink and lamp gold
/// by night (Qiyam).
const mushafTheme = AppTheme(
  id: 'mushaf',
  name: 'Mushaf',
  light: Palette(
    brightness: Brightness.light,
    surfacePage: Color(0xFFF6F1E7),
    surfaceRaised: Color(0xFFFFFDF7),
    inkAyah: Color(0xFF2B2A26),
    inkPrimary: Color(0xFF2B2A26),
    inkSecondary: Color(0xFF5E6B58),
    inkMuted: Color(0xFF7A7465),
    accent: Color(0xFFB08D4A),
    onAccent: Color(0xFFFFFDF7),
    brand: Color(0xFF8DA083),
    brandSoft: Color(0xFFDCE3D5),
    border: Color(0xFFE2DACA),
    glassTint: Color(0x66FFFDF7),
    glassEdge: Color(0xCCFFFFFF),
    ribbonTilawah: Color(0xFFB08D4A),
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
    brandSoft: Color(0xFF2A3127),
    border: Color(0xFF2C2E29),
    glassTint: Color(0x1AC9A25A),
    glassEdge: Color(0x38E9E2D0),
    ribbonTilawah: Color(0xFFC9A25A),
    ribbonHafalan: Color(0xFF8DA083),
    ribbonMurajaah: Color(0xFFB98468),
  ),
);
