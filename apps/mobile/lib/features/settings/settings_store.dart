import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dzikir/dzikir_services.dart';

/// Where settings are kept: SharedPreferences in the app, a map in tests.
abstract interface class SettingsBackend {
  String? read(String key);
  Future<void> write(String key, String value);
}

class SharedPrefsSettingsBackend implements SettingsBackend {
  SharedPrefsSettingsBackend._(this._prefs);

  static Future<SharedPrefsSettingsBackend> open() async =>
      SharedPrefsSettingsBackend._(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        ),
      );

  final SharedPreferencesWithCache _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
}

/// For tests.
class InMemorySettingsBackend implements SettingsBackend {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// Restores the user's choices at startup and saves every change after.
///
/// Only what was stored is applied; anything missing or unrecognised keeps
/// the controller's own default, so defaults live in one place.
class SettingsStore {
  SettingsStore(this._backend);

  final SettingsBackend _backend;

  static const _theme = 'settings.theme';
  static const _mode = 'settings.mode';
  static const _glass = 'settings.glass';
  static const _darkSessions = 'settings.darkSessions';
  static const _vibrate = 'settings.vibrate';
  static const _layers = 'settings.layers';
  static const _arabicSize = 'settings.arabicSize';

  ThemeController restoreTheme() {
    final controller = ThemeController();
    if (_backend.read(_theme) case final id?) controller.select(id);
    if (_enum(AppThemeMode.values, _mode) case final mode?) {
      controller.mode = mode;
    }
    if (_enum(GlassMode.values, _glass) case final glass?) {
      controller.glassMode = glass;
    }
    if (_bool(_darkSessions) case final dark?) controller.darkSessions = dark;

    controller.addListener(() {
      // The chosen theme, not one being previewed.
      _save(_theme, controller.selectedTheme.id);
      _save(_mode, controller.mode.name);
      _save(_glass, controller.glassMode.name);
      _save(_darkSessions, '${controller.darkSessions}');
    });
    return controller;
  }

  DzikirSettings restoreDzikirSettings() {
    final settings = DzikirSettings();
    if (_bool(_vibrate) case final vibrate?) settings.vibrate = vibrate;
    if (_enum(DzikirTextLayers.values, _layers) case final layers?) {
      settings.layers = layers;
    }
    if (_enum(DzikirArabicSize.values, _arabicSize) case final size?) {
      settings.arabicSize = size;
    }

    settings.addListener(() {
      _save(_vibrate, '${settings.vibrate}');
      _save(_layers, settings.layers.name);
      _save(_arabicSize, settings.arabicSize.name);
    });
    return settings;
  }

  void _save(String key, String value) {
    if (_backend.read(key) != value) unawaited(_backend.write(key, value));
  }

  T? _enum<T extends Enum>(List<T> values, String key) =>
      values.asNameMap()[_backend.read(key)];

  bool? _bool(String key) => switch (_backend.read(key)) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}
