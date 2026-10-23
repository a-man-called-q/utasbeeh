import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dzikir_fixture.dart';

void main() {
  testWidgets('the Pengaturan tab switches between both free themes', (
    tester,
  ) async {
    final controller = ThemeController(mode: AppThemeMode.light);
    await tester.pumpWidget(DzikirHarness().app(themeController: controller));

    await tester.tap(find.byKey(const ValueKey('tab-pengaturan')));
    await tester.pump();
    expect(find.text('Pengaturan'), findsWidgets);

    await tester.tap(find.text(lazuardiTheme.name));
    await tester.pump();
    expect(controller.isPreviewing, isFalse);
    expect(controller.selectedTheme, lazuardiTheme);
    expect(controller.activeTheme, lazuardiTheme);

    await tester.tap(find.text(mushafTheme.name));
    await tester.pump();
    expect(controller.activeTheme, mushafTheme);

    await tester.tap(find.text('Ikut mode'));
    await tester.pump();
    expect(controller.darkSessions, isFalse);
  });
}
