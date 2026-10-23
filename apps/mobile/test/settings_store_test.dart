import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh/features/dzikir/dzikir_services.dart';
import 'package:tasbeeh/features/settings/settings_store.dart';

void main() {
  test('nothing stored keeps every default', () {
    final store = SettingsStore(InMemorySettingsBackend());
    final theme = store.restoreTheme();
    final dzikir = store.restoreDzikirSettings();

    final fresh = ThemeController();
    expect(theme.selectedTheme, fresh.selectedTheme);
    expect(theme.mode, fresh.mode);
    expect(theme.glassMode, fresh.glassMode);
    expect(theme.darkSessions, fresh.darkSessions);
    expect(dzikir.vibrate, isTrue);
    expect(dzikir.layers, DzikirTextLayers.all);
    expect(dzikir.arabicSize, DzikirArabicSize.medium);
  });

  test('choices survive a restart', () {
    final backend = InMemorySettingsBackend();
    final first = SettingsStore(backend);
    first.restoreTheme()
      ..select(lazuardiTheme.id)
      ..mode = AppThemeMode.dark
      ..glassMode = GlassMode.solid
      ..darkSessions = false;
    first.restoreDzikirSettings()
      ..vibrate = false
      ..layers = DzikirTextLayers.arabic
      ..arabicSize = DzikirArabicSize.large;

    final second = SettingsStore(backend);
    final theme = second.restoreTheme();
    final dzikir = second.restoreDzikirSettings();
    expect(theme.selectedTheme, lazuardiTheme);
    expect(theme.mode, AppThemeMode.dark);
    expect(theme.glassMode, GlassMode.solid);
    expect(theme.darkSessions, isFalse);
    expect(dzikir.vibrate, isFalse);
    expect(dzikir.layers, DzikirTextLayers.arabic);
    expect(dzikir.arabicSize, DzikirArabicSize.large);
  });

  test('a previewed theme is not saved as the choice', () {
    final backend = InMemorySettingsBackend();
    SettingsStore(backend).restoreTheme()
      ..mode = AppThemeMode.light
      ..preview(lazuardiTheme.id);

    expect(SettingsStore(backend).restoreTheme().selectedTheme, mushafTheme);
  });

  test('unknown stored values fall back to defaults', () {
    final backend = InMemorySettingsBackend()
      ..values.addAll({
        'settings.theme': 'gone',
        'settings.mode': 'sepia',
        'settings.vibrate': 'maybe',
        'settings.layers': 'everything',
      });
    final store = SettingsStore(backend);
    final theme = store.restoreTheme();
    final dzikir = store.restoreDzikirSettings();
    expect(theme.selectedTheme, mushafTheme);
    expect(theme.mode, AppThemeMode.system);
    expect(dzikir.vibrate, isTrue);
    expect(dzikir.layers, DzikirTextLayers.all);
  });
}
