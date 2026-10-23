import 'package:flutter/widgets.dart';

import '../app_theme.dart';
import '../palette.dart';

/// Premium sample theme: lapis blue with gold. Also serves as the reference
/// for how a paid theme is declared.
const lazuardiTheme = AppTheme(
  id: 'lazuardi',
  name: 'Lazuardi',
  isPremium: true,
  light: Palette(
    brightness: Brightness.light,
    surfacePage: Color(0xFFEEF1F6),
    surfaceRaised: Color(0xFFFAFBFD),
    inkAyah: Color(0xFF1A2333),
    inkPrimary: Color(0xFF1A2333),
    inkSecondary: Color(0xFF4A5A75),
    inkMuted: Color(0xFF6E7A8F),
    accent: Color(0xFFB8913F),
    onAccent: Color(0xFFFAFBFD),
    brand: Color(0xFF3E5C8A),
    brandSoft: Color(0xFFD5DEEC),
    border: Color(0xFFD8DEE8),
    glassTint: Color(0x33FAFBFD),
    glassEdge: Color(0xCCFFFFFF),
    glassShade: Color(0x331A2333),
    ribbonTilawah: Color(0xFFB8913F),
    ribbonHafalan: Color(0xFF3E5C8A),
    ribbonMurajaah: Color(0xFF7A5C8A),
  ),
  dark: Palette(
    brightness: Brightness.dark,
    surfacePage: Color(0xFF0B1220),
    surfaceRaised: Color(0xFF16203A),
    inkAyah: Color(0xFFE6EAF2),
    inkPrimary: Color(0xFFE6EAF2),
    inkSecondary: Color(0xFFA9B4C8),
    inkMuted: Color(0xFF7C889E),
    accent: Color(0xFFC9A25A),
    onAccent: Color(0xFF0B1220),
    brand: Color(0xFF7D9BCB),
    brandSoft: Color(0xFF1E2C4A),
    border: Color(0xFF222D45),
    glassTint: Color(0x1A7D9BCB),
    glassEdge: Color(0x5CE6EAF2),
    glassShade: Color(0x29E6EAF2),
    ribbonTilawah: Color(0xFFC9A25A),
    ribbonHafalan: Color(0xFF7D9BCB),
    ribbonMurajaah: Color(0xFFA88BC0),
  ),
);
