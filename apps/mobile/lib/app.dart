import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:quran_core/quran_core.dart';

import 'features/dzikir/dzikir_services.dart';
import 'features/quran/quran_store.dart';
import 'shell/home_shell.dart';

class TasbeehApp extends StatelessWidget {
  const TasbeehApp({
    super.key,
    required this.themeController,
    required this.dzikirServices,
    required this.quranLibrary,
    required this.quranStore,
  });

  final ThemeController themeController;
  final DzikirServices dzikirServices;
  final QuranLibrary quranLibrary;
  final QuranStore quranStore;

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
            home: HomeShell(
              services: dzikirServices,
              quranLibrary: quranLibrary,
              quran: quranStore,
            ),
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
