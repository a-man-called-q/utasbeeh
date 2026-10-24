import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:quran_core/quran_core.dart';

import 'quran/bookmark_store.dart';
import 'shell.dart';
import 'tasbih/tasbih_feedback.dart';
import 'tasbih/tasbih_store.dart';

/// Tasbeeh Lite: the default theme following the system's light or dark,
/// with no settings to choose.
class LiteApp extends StatelessWidget {
  LiteApp({
    super.key,
    required this.tasbih,
    required this.quranLibrary,
    required this.bookmarks,
    this.feedback = const HapticTasbihFeedback(),
    ThemeController? themeController,
  }) : themeController = themeController ?? ThemeController();

  final TasbihStore tasbih;
  final TasbihFeedback feedback;
  final QuranLibrary quranLibrary;
  final BookmarkStore bookmarks;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      controller: themeController,
      child: Builder(
        builder: (context) {
          final palette = AppThemeScope.of(context).palette;
          return MaterialApp(
            title: 'Tasbeeh Lite',
            debugShowCheckedModeBanner: false,
            theme: _materialTheme(palette),
            home: LiteShell(
              tasbih: tasbih,
              feedback: feedback,
              quranLibrary: quranLibrary,
              bookmarks: bookmarks,
            ),
          );
        },
      ),
    );
  }

  /// Keeps stock Material pieces (dialogs, snack bars, text fields) in step
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
