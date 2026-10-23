import 'package:flutter/foundation.dart';

import '../glass/glass_mode.dart';
import 'app_theme.dart';
import 'theme_registry.dart';

enum AppThemeMode { system, light, dark }

/// Holds the user's theme choices and decides which theme is active.
///
/// Purchases live outside this class: the purchase layer reports what the
/// user owns through [setUnlockedThemes]. Persistence is also the caller's
/// job; read the getters and restore through the constructor.
class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeRegistry? registry,
    String? selectedThemeId,
    this._mode = AppThemeMode.system,
    this._glassMode = GlassMode.frosted,
    this._darkSessions = true,
    Set<String> unlockedThemeIds = const {},
  }) : registry = registry ?? ThemeRegistry.builtIn,
       _unlockedIds = {...unlockedThemeIds} {
    _selectedId = selectedThemeId ?? this.registry.fallback.id;
  }

  final ThemeRegistry registry;

  late String _selectedId;
  String? _previewId;
  Set<String> _unlockedIds;
  AppThemeMode _mode;
  GlassMode _glassMode;
  bool _darkSessions;

  AppThemeMode get mode => _mode;
  GlassMode get glassMode => _glassMode;

  /// Whether dzikir sessions always use the theme's dark palette, so the
  /// screen stays dim at night and in the masjid.
  bool get darkSessions => _darkSessions;
  Set<String> get unlockedThemeIds => Set.unmodifiable(_unlockedIds);

  bool isUnlocked(AppTheme theme) =>
      !theme.isPremium || _unlockedIds.contains(theme.id);

  /// The theme the user chose, or the fallback if it is unknown or no longer
  /// unlocked (e.g. a refunded purchase).
  AppTheme get selectedTheme {
    final theme = registry.byId(_selectedId);
    return theme != null && isUnlocked(theme) ? theme : registry.fallback;
  }

  AppTheme? get previewTheme =>
      _previewId == null ? null : registry.byId(_previewId!);

  bool get isPreviewing => previewTheme != null;

  /// What the UI paints with right now.
  AppTheme get activeTheme => previewTheme ?? selectedTheme;

  /// Selects [id] as the user's theme. Returns false when the theme is
  /// unknown or locked; use [preview] for locked themes instead.
  bool select(String id) {
    final theme = registry.byId(id);
    if (theme == null || !isUnlocked(theme)) return false;
    _selectedId = id;
    _previewId = null;
    notifyListeners();
    return true;
  }

  /// Shows any theme, locked or not, without selecting it.
  void preview(String id) {
    if (registry.byId(id) == null || _previewId == id) return;
    _previewId = id;
    notifyListeners();
  }

  void endPreview() {
    if (_previewId == null) return;
    _previewId = null;
    notifyListeners();
  }

  void setUnlockedThemes(Set<String> ids) {
    if (setEquals(ids, _unlockedIds)) return;
    _unlockedIds = {...ids};
    notifyListeners();
  }

  set mode(AppThemeMode value) {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
  }

  set glassMode(GlassMode value) {
    if (value == _glassMode) return;
    _glassMode = value;
    notifyListeners();
  }

  set darkSessions(bool value) {
    if (value == _darkSessions) return;
    _darkSessions = value;
    notifyListeners();
  }
}
