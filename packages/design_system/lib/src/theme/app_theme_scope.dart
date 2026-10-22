import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../glass/glass_mode.dart';
import '../tokens/layout_tokens.dart';
import '../tokens/text_tokens.dart';
import 'app_theme.dart';
import 'palette.dart';
import 'theme_controller.dart';

/// Resolves [ThemeController] against the platform brightness and provides
/// the result to the tree: Mix tokens through [MixScope], and the rest
/// through [AppThemeScope.of].
///
/// Place it above `MaterialApp`/`WidgetsApp` so every route shares it.
class AppThemeScope extends StatefulWidget {
  const AppThemeScope({
    super.key,
    required this.controller,
    required this.child,
  });

  final ThemeController controller;
  final Widget child;

  static ResolvedAppTheme of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_ResolvedAppThemeScope>();
    assert(scope != null, 'No AppThemeScope found in context');
    return scope!.data;
  }

  @override
  State<AppThemeScope> createState() => _AppThemeScopeState();
}

class _AppThemeScopeState extends State<AppThemeScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  Brightness _brightnessFor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => Brightness.light,
    AppThemeMode.dark => Brightness.dark,
    AppThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final theme = controller.activeTheme;
        final palette = theme.paletteFor(_brightnessFor(controller.mode));
        return _ResolvedAppThemeScope(
          data: ResolvedAppTheme(
            controller: controller,
            theme: theme,
            palette: palette,
            glassMode: controller.glassMode,
          ),
          child: MixScope(
            colors: palette.tokens,
            textStyles: AppText.scale,
            spaces: AppSpace.scale,
            radii: AppRadius.scale,
            child: widget.child,
          ),
        );
      },
    );
  }
}

@immutable
class ResolvedAppTheme {
  const ResolvedAppTheme({
    required this.controller,
    required this.theme,
    required this.palette,
    required this.glassMode,
  });

  final ThemeController controller;
  final AppTheme theme;
  final Palette palette;
  final GlassMode glassMode;

  Brightness get brightness => palette.brightness;

  @override
  bool operator ==(Object other) =>
      other is ResolvedAppTheme &&
      other.controller == controller &&
      other.theme == theme &&
      other.palette == palette &&
      other.glassMode == glassMode;

  @override
  int get hashCode => Object.hash(controller, theme, palette, glassMode);
}

class _ResolvedAppThemeScope extends InheritedWidget {
  const _ResolvedAppThemeScope({required this.data, required super.child});

  final ResolvedAppTheme data;

  @override
  bool updateShouldNotify(_ResolvedAppThemeScope oldWidget) =>
      data != oldWidget.data;
}
