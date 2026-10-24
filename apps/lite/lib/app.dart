import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:quran_core/quran_core.dart';

import 'quran/bookmark_store.dart';
import 'settings/settings_store.dart';
import 'shell.dart';
import 'tasbih/tasbih_feedback.dart';
import 'tasbih/tasbih_store.dart';

/// Tasbeeh Lite: a counter and Qur'an bookmarks, with a few settings.
class LiteApp extends StatelessWidget {
  const LiteApp({
    super.key,
    required this.themeController,
    required this.settings,
    required this.tasbih,
    required this.quranLibrary,
    required this.bookmarks,
    this.feedback = const HapticTasbihFeedback(),
  });

  final LiteSettings settings;
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
              settings: settings,
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
