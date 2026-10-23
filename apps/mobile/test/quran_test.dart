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

  testWidgets('each ayah can be bookmarked on its own', (tester) async {
    final h = DzikirHarness();
    await openQuran(tester, h);

    await tester.tap(find.byTooltip('Tandai ayat').first);
    await tester.pump();
    expect(h.quran.isBookmarked((surah: 1, ayah: 1)), isTrue);
    expect(h.quran.isBookmarked((surah: 1, ayah: 2)), isFalse);
    expect(find.byTooltip('Hapus tanda ayat'), findsOneWidget);

    await tester.tap(find.byTooltip('Hapus tanda ayat'));
    await tester.pump();
    expect(h.quran.isBookmarked((surah: 1, ayah: 1)), isFalse);
  });

  testWidgets('scrolling moves the reading place and saves it', (tester) async {
    final h = DzikirHarness();
    await openQuran(tester, h);
    expect(find.text('Contoh surah · mushaf lengkap menyusul'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    final last = h.quran.lastRead;
    expect(last, isNotNull);
    expect(last, isNot((surah: 1, ayah: 1)));
    expect(
      find.text('Terakhir dibaca · Al-Fātiḥah 1:${last!.ayah}'),
      findsOneWidget,
    );
  });
}
