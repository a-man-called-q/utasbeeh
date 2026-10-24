import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh/features/quran/quran_store.dart';
import 'package:tasbeeh/features/settings/settings_store.dart';

import 'support/dzikir_fixture.dart';

void main() {
  group('QuranStore', () {
    test('bookmarks and the last-read ayah survive a restart', () {
      final backend = InMemorySettingsBackend();
      QuranStore(backend)
        ..toggleBookmark((surah: 2, ayah: 255))
        ..toggleBookmark((surah: 1, ayah: 5))
        ..toggleBookmark((surah: 1, ayah: 5))
        ..lastRead = (surah: 112, ayah: 3);

      final again = QuranStore(backend);
      expect(again.isBookmarked((surah: 2, ayah: 255)), isTrue);
      expect(again.isBookmarked((surah: 1, ayah: 5)), isFalse);
      expect(again.lastRead, (surah: 112, ayah: 3));
    });

    test('ignores malformed stored values', () {
      final backend = InMemorySettingsBackend()
        ..values.addAll({
          'quran.bookmarks': '1:2,nope,3:,4:4',
          'quran.lastRead': 'x',
        });
      final store = QuranStore(backend);
      expect(store.isBookmarked((surah: 1, ayah: 2)), isTrue);
      expect(store.isBookmarked((surah: 4, ayah: 4)), isTrue);
      expect(store.lastRead, isNull);
    });
  });

  Future<void> openQuran(WidgetTester tester, DzikirHarness h) async {
    await tester.pumpWidget(h.app());
    await tester.tap(find.byKey(const ValueKey('tab-quran')));
    await tester.pumpAndSettle();
  }

  testWidgets('the tab lists surahs and opens one to read', (tester) async {
    final h = DzikirHarness();
    await openQuran(tester, h);
    expect(find.text('SURAH'), findsOneWidget);
    expect(find.text('LANJUTKAN MEMBACA'), findsNothing);

    await tester.tap(find.text('1. Al-Fātiḥah'));
    await tester.pumpAndSettle();
    expect(find.text('Fatihah 1'), findsOneWidget);
    expect(find.text('MAKKIYAH · 7 AYAT'), findsOneWidget);
  });

  testWidgets('bookmarks are per ayah and listed on the tab', (tester) async {
    final h = DzikirHarness();
    await openQuran(tester, h);
    await tester.tap(find.text('112. Al-Ikhlāṣ'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tandai ayat').first);
    await tester.pump();
    expect(h.quran.isBookmarked((surah: 112, ayah: 1)), isTrue);
    expect(h.quran.isBookmarked((surah: 112, ayah: 2)), isFalse);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('DITANDAI'), findsOneWidget);
    expect(find.text('Al-Ikhlāṣ 112:1'), findsOneWidget);
  });

  testWidgets('scrolling saves the place and the tab offers to resume', (
    tester,
  ) async {
    final h = DzikirHarness();
    await openQuran(tester, h);
    await tester.tap(find.text('1. Al-Fātiḥah'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final last = h.quran.lastRead;
    expect(last?.surah, 1);
    expect(last!.ayah, greaterThan(1));

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('LANJUTKAN MEMBACA'), findsOneWidget);
    expect(find.text('Ayat ${last.ayah} dari 7'), findsOneWidget);
  });

  testWidgets('resuming opens at the saved ayah and keeps it', (tester) async {
    final h = DzikirHarness();
    h.quran.lastRead = (surah: 112, ayah: 3);
    await openQuran(tester, h);

    await tester.tap(find.text('Ayat 3 dari 4'));
    await tester.pumpAndSettle();
    // The opened ayah sits just under the bar, above the reading line.
    expect(tester.getTopLeft(find.text('Ikhlas 3')).dy, greaterThan(144));
    expect(
      tester.getTopLeft(find.text('Ikhlas 3')).dy,
      lessThan(tester.getTopLeft(find.text('Ikhlas 4')).dy),
    );
    expect(h.quran.lastRead, (surah: 112, ayah: 3));
  });
}
