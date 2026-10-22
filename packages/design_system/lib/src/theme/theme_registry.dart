import 'app_theme.dart';
import 'themes/lazuardi.dart';
import 'themes/mushaf.dart';

/// The list of themes the app knows about.
///
/// Adding a theme: create a file in `themes/`, then add it to [builtIn].
/// The first theme is the free fallback used whenever the selected theme is
/// unknown or not unlocked.
class ThemeRegistry {
  ThemeRegistry(this.themes)
    : assert(themes.isNotEmpty, 'A registry needs at least one theme'),
      assert(!themes.first.isPremium, 'The fallback theme must be free'),
      assert(
        themes.map((t) => t.id).toSet().length == themes.length,
        'Theme ids must be unique',
      );

  static final builtIn = ThemeRegistry(const [mushafTheme, lazuardiTheme]);

  final List<AppTheme> themes;

  AppTheme get fallback => themes.first;

  AppTheme? byId(String id) {
    for (final theme in themes) {
      if (theme.id == id) return theme;
    }
    return null;
  }
}
