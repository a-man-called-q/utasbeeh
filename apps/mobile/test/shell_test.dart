import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dzikir_fixture.dart';

void main() {
  testWidgets('home features the dzikir for this hour', (tester) async {
    final h = DzikirHarness();
    await tester.pumpWidget(h.app());

    expect(find.text('Jumat, 23 Oktober'), findsOneWidget);
    expect(find.text('Sekarang'), findsOneWidget);
    expect(find.text('Dzikir pagi'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);

    await tester.tap(find.text('Dzikir pagi'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets("outside the windows home features ba'da shalat", (tester) async {
    final h = DzikirHarness(now: DateTime(2026, 10, 23, 13));
    await tester.pumpWidget(h.app());

    expect(find.text('Setelah shalat'), findsOneWidget);
    // The fixture has no ba'da shalat, so the first sequence stands in.
    expect(find.text('Dzikir pagi'), findsOneWidget);
  });

  testWidgets("the Qur'an card switches to the Qur'an tab", (tester) async {
    await tester.pumpWidget(DzikirHarness().app());

    await tester.tap(find.text('Al-Fātiḥah'));
    await tester.pump();
    expect(find.text('Pratinjau pembaca'), findsOneWidget);
    expect(find.text('Pembukaan'), findsOneWidget);
  });

  group('session brightness', () {
    Color sessionBackground(WidgetTester tester) =>
        tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor!;

    testWidgets('sessions are dark by default in light mode', (tester) async {
      final h = DzikirHarness();
      await tester.pumpWidget(h.app());
      await tester.tap(find.text('Dzikir pagi'));
      await tester.pumpAndSettle();

      expect(sessionBackground(tester), mushafTheme.dark.surfacePage);
    });

    testWidgets('"Ikut mode" keeps sessions light', (tester) async {
      final h = DzikirHarness();
      final theme = ThemeController(
        mode: AppThemeMode.light,
        glassMode: GlassMode.solid,
        darkSessions: false,
      );
      await tester.pumpWidget(h.app(themeController: theme));
      await tester.tap(find.text('Dzikir pagi'));
      await tester.pumpAndSettle();

      expect(sessionBackground(tester), mushafTheme.light.surfacePage);
    });
  });
}
