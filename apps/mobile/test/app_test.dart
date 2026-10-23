import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dzikir_fixture.dart';

void main() {
  testWidgets('appearance previews a locked theme without selecting it', (
    tester,
  ) async {
    final controller = ThemeController(mode: AppThemeMode.light);
    await tester.pumpWidget(DzikirHarness().app(themeController: controller));

    await tester.tap(find.byTooltip('Tampilan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(lazuardiTheme.name));
    await tester.pump();

    expect(controller.isPreviewing, isTrue);
    expect(controller.selectedTheme, mushafTheme);
    expect(find.text('Selesai pratinjau'), findsOneWidget);

    await tester.tap(find.text('Selesai pratinjau'));
    await tester.pump();
    expect(controller.activeTheme, mushafTheme);

    await tester.tap(find.text('Ikut mode'));
    await tester.pump();
    expect(controller.darkSessions, isFalse);
  });
}
