import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh/app.dart';

void main() {
  testWidgets('preview switches to a locked theme as a preview only', (
    tester,
  ) async {
    final controller = ThemeController(mode: AppThemeMode.light);
    await tester.pumpWidget(TasbeehApp(themeController: controller));
    await tester.pump();

    expect(find.text('Al-Fātiḥah'), findsOneWidget);

    await tester.tap(find.text(lazuardiTheme.name));
    await tester.pump();

    expect(controller.isPreviewing, isTrue);
    expect(controller.selectedTheme, mushafTheme);
    expect(find.text('Selesai pratinjau'), findsOneWidget);

    await tester.tap(find.text('Selesai pratinjau'));
    await tester.pump();
    expect(controller.activeTheme, mushafTheme);
  });
}
