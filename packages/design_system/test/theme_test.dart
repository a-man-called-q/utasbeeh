import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Both launch themes are free, so locking is exercised with a paid stand-in.
final _premiumTheme = AppTheme(
  id: 'test-premium',
  name: 'Premium',
  isPremium: true,
  light: lazuardiTheme.light,
  dark: lazuardiTheme.dark,
);
final _registry = ThemeRegistry([mushafTheme, _premiumTheme]);

void main() {
  group('ThemeRegistry.builtIn', () {
    final registry = ThemeRegistry.builtIn;

    test('every palette defines every color token', () {
      for (final theme in registry.themes) {
        for (final palette in [theme.light, theme.dark]) {
          expect(
            palette.tokens.keys.toSet(),
            AppColors.values.toSet(),
            reason: '${theme.id} ${palette.brightness.name}',
          );
        }
      }
    });

    test('light and dark palettes carry the matching brightness', () {
      for (final theme in registry.themes) {
        expect(theme.light.brightness, Brightness.light, reason: theme.id);
        expect(theme.dark.brightness, Brightness.dark, reason: theme.id);
      }
    });

    test('fallback is the free Mushaf theme', () {
      expect(registry.fallback, mushafTheme);
      expect(registry.fallback.isPremium, isFalse);
    });

    test('both launch themes are free', () {
      expect(registry.themes, [mushafTheme, lazuardiTheme]);
      expect(registry.themes.where((t) => t.isPremium), isEmpty);
    });
  });

  group('ThemeController', () {
    test('locked themes cannot be selected but can be previewed', () {
      final controller = ThemeController(registry: _registry);

      expect(controller.select(_premiumTheme.id), isFalse);
      expect(controller.activeTheme, mushafTheme);

      controller.preview(_premiumTheme.id);
      expect(controller.isPreviewing, isTrue);
      expect(controller.activeTheme, _premiumTheme);
      expect(controller.selectedTheme, mushafTheme);

      controller.endPreview();
      expect(controller.activeTheme, mushafTheme);
    });

    test('unlocked premium themes can be selected', () {
      final controller = ThemeController(registry: _registry)
        ..setUnlockedThemes({_premiumTheme.id});

      expect(controller.select(_premiumTheme.id), isTrue);
      expect(controller.activeTheme, _premiumTheme);
    });

    test('losing an entitlement falls back to the free theme', () {
      final controller = ThemeController(
        registry: _registry,
        selectedThemeId: _premiumTheme.id,
        unlockedThemeIds: {_premiumTheme.id},
      );
      expect(controller.activeTheme, _premiumTheme);

      controller.setUnlockedThemes({});
      expect(controller.activeTheme, mushafTheme);
    });

    test('unknown ids are ignored', () {
      final controller = ThemeController(
        registry: _registry,
        selectedThemeId: 'gone',
      );

      expect(controller.activeTheme, mushafTheme);
      expect(controller.select('nope'), isFalse);
    });
  });

  group('AppThemeScope', () {
    Widget host(ThemeController controller, Widget child) => AppThemeScope(
      controller: controller,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    );

    testWidgets('resolves color tokens from the active palette', (
      tester,
    ) async {
      final controller = ThemeController(mode: AppThemeMode.dark);
      late Color page;
      await tester.pumpWidget(
        host(
          controller,
          Builder(
            builder: (context) {
              page = AppColors.surfacePage.resolve(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(page, mushafTheme.dark.surfacePage);

      controller.mode = AppThemeMode.light;
      await tester.pump();
      expect(page, mushafTheme.light.surfacePage);
    });

    for (final mode in GlassMode.values) {
      testWidgets('GlassSurface renders in ${mode.name} mode', (tester) async {
        final controller = ThemeController(glassMode: mode);
        await tester.pumpWidget(
          host(
            controller,
            const GlassSurface(child: SizedBox(width: 120, height: 48)),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(GlassSurface), findsOneWidget);
      });
    }
  });
}
