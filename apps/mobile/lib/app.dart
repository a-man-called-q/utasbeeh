import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'features/dzikir/dzikir_services.dart';
import 'shell/home_shell.dart';

class TasbeehApp extends StatelessWidget {
  const TasbeehApp({
    super.key,
    required this.themeController,
    required this.dzikirServices,
  });

  final ThemeController themeController;
  final DzikirServices dzikirServices;

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      controller: themeController,
      child: Builder(
        builder: (context) {
          final palette = AppThemeScope.of(context).palette;
          return MaterialApp(
            title: 'Tasbeeh',
            debugShowCheckedModeBanner: false,
            theme: _materialTheme(palette),
            home: HomeShell(services: dzikirServices),
          );
        },
      ),
    );
  }

  /// Keeps stock Material pieces (selection, scrollbars, dialogs) in step
  /// with the active palette. Our own UI reads Mix tokens instead.
  ThemeData _materialTheme(Palette palette) {
    return ThemeData(
      brightness: palette.brightness,
      scaffoldBackgroundColor: palette.surfacePage,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.brand,
        brightness: palette.brightness,
        surface: palette.surfacePage,
        primary: palette.accent,
        onPrimary: palette.onAccent,
      ),
      splashFactory: NoSplash.splashFactory,
    );
  }
}
