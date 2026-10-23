import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dzikir_fixture.dart';

void main() {
  testWidgets('appearance switches between both free themes', (tester) async {
    final controller = ThemeController(mode: AppThemeMode.light);
    await tester.pumpWidget(DzikirHarness().app(themeController: controller));

    await tester.tap(find.byTooltip('Tampilan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(lazuardiTheme.name));
    await tester.pump();
    expect(controller.isPreviewing, isFalse);
    expect(controller.activeTheme, lazuardiTheme);

    await tester.tap(find.text(mushafTheme.name));
    await tester.pump();
    expect(controller.activeTheme, mushafTheme);

    await tester.tap(find.text('Ikut mode'));
    await tester.pump();
    expect(controller.darkSessions, isFalse);
  });
}
