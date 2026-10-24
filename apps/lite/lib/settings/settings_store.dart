import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';

import '../storage.dart';

/// Arabic text size in the reader, for readers who need it larger.
enum ArabicSize {
  small(0.85),
  medium(1),
  large(1.2);

  const ArabicSize(this.scale);

  final double scale;
}

/// Preferences that are not about the theme.
class LiteSettings extends ChangeNotifier {
  LiteSettings({this._vibrate = true, this._arabicSize = ArabicSize.medium});

  bool _vibrate;
  ArabicSize _arabicSize;

  /// Whether counting vibrates.
  bool get vibrate => _vibrate;
  set vibrate(bool value) => _set(() => _vibrate = value, value == _vibrate);

  ArabicSize get arabicSize => _arabicSize;
  set arabicSize(ArabicSize value) =>
      _set(() => _arabicSize = value, value == _arabicSize);

  void _set(void Function() apply, bool unchanged) {
    if (unchanged) return;
    apply();
    notifyListeners();
  }
}

/// Restores the user's choices at startup and saves every change after.
///
/// Only what was stored is applied; anything missing or unrecognised keeps
/// the default, so defaults live in one place.
class SettingsStore {
  SettingsStore(this._storage);

  final Storage _storage;

  static const _theme = 'settings.theme';
  static const _mode = 'settings.mode';
  static const _vibrate = 'settings.vibrate';
  static const _arabicSize = 'settings.arabicSize';

  ThemeController restoreTheme() {
    final controller = ThemeController();
    if (_storage.read(_theme) case final id?) controller.select(id);
    if (_enum(AppThemeMode.values, _mode) case final mode?) {
      controller.mode = mode;
    }

    controller.addListener(() {
      _save(_theme, controller.selectedTheme.id);
      _save(_mode, controller.mode.name);
    });
    return controller;
  }

  LiteSettings restoreSettings() {
    final settings = LiteSettings();
    if (_bool(_vibrate) case final vibrate?) settings.vibrate = vibrate;
    if (_enum(ArabicSize.values, _arabicSize) case final size?) {
      settings.arabicSize = size;
    }

    settings.addListener(() {
      _save(_vibrate, '${settings.vibrate}');
      _save(_arabicSize, settings.arabicSize.name);
    });
    return settings;
  }

  void _save(String key, String value) {
    if (_storage.read(key) != value) unawaited(_storage.write(key, value));
  }

  T? _enum<T extends Enum>(List<T> values, String key) =>
      values.asNameMap()[_storage.read(key)];

  bool? _bool(String key) => switch (_storage.read(key)) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}
