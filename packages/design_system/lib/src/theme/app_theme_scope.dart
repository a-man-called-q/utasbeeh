import 'package:flutter/services.dart';
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
        return _provide(
          ResolvedAppTheme(
            controller: controller,
            theme: theme,
            palette: theme.paletteFor(_brightnessFor(controller.mode)),
            glassMode: controller.glassMode,
          ),
          widget.child,
        );
      },
    );
  }
}

/// Re-provides the active theme at a fixed brightness for one subtree, e.g.
/// a dzikir session that stays dark whatever the app's light/dark setting.
class AppBrightnessOverride extends StatelessWidget {
  const AppBrightnessOverride({
    super.key,
    required this.brightness,
    required this.child,
  });

  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = AppThemeScope.of(context);
    return _provide(
      ResolvedAppTheme(
        controller: parent.controller,
        theme: parent.theme,
        palette: parent.theme.paletteFor(brightness),
        glassMode: parent.glassMode,
      ),
      child,
    );
  }
}

Widget _provide(ResolvedAppTheme data, Widget child) {
  final dark = data.brightness == Brightness.dark;
  return _ResolvedAppThemeScope(
    data: data,
    child: MixScope(
      colors: data.palette.tokens,
      textStyles: AppText.scale,
      spaces: AppSpace.scale,
      radii: AppRadius.scale,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: child,
      ),
    ),
  );
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
