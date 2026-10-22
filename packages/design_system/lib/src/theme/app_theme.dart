import 'package:flutter/widgets.dart';

import 'palette.dart';

/// A selectable color theme. Each theme carries both a light and a dark
/// palette, so the user's light/dark preference works with every theme.
///
/// Themes change color only; typography, spacing and radii are shared.
@immutable
class AppTheme {
  const AppTheme({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
    this.isPremium = false,
  });

  /// Stable id used for persistence and purchase entitlements. Never rename.
  final String id;
  final String name;
  final Palette light;
  final Palette dark;

  /// Premium themes need an entitlement to be selected, but can be previewed.
  final bool isPremium;

  Palette paletteFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
