import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_core/quran_core.dart';
import 'package:tasbeeh_lite/app.dart';
import 'package:tasbeeh_lite/quran/bookmark_store.dart';
import 'package:tasbeeh_lite/quran/surah_picker_screen.dart';
import 'package:tasbeeh_lite/settings/settings_store.dart';
import 'package:tasbeeh_lite/storage.dart';
import 'package:tasbeeh_lite/tasbih/tasbih_feedback.dart';
import 'package:tasbeeh_lite/tasbih/tasbih_store.dart';

/// Two short surahs, so tests don't parse the whole mushaf.
final _quran = QuranLibrary([
  Surah(
    number: 1,
    name: 'Al-Fātiḥah',
    meaning: 'Pembuka',
    arabicName: 'الفاتحة',
    makki: true,
    ayat: [
      for (var a = 1; a <= 7; a++)
        Ayah(number: a, arabic: 'آية $a', translation: 'Fatihah $a'),
    ],
  ),
  Surah(
    number: 112,
    name: 'Al-Ikhlāṣ',
    meaning: 'Ikhlas',
    arabicName: 'الاخلاص',
    makki: true,
    ayat: [
      for (var a = 1; a <= 4; a++)
        Ayah(number: a, arabic: 'آية $a', translation: 'Ikhlas $a'),
    ],
  ),
]);

class _RecordingFeedback implements TasbihFeedback {
  final counts = <int>[];
  var steps = 0;

  @override
  void onCount(int count) => counts.add(count);

  @override
  void onStep() => steps++;
}

class _Harness {
  final storage = InMemoryStorage();
  final feedback = _RecordingFeedback();
  late final tasbih = TasbihStore(storage);
  late final bookmarks = BookmarkStore(storage);
  late final _settingsStore = SettingsStore(storage);
  late final theme = _settingsStore.restoreTheme();
  late final settings = _settingsStore.restoreSettings();

  Widget app() => LiteApp(
    themeController: theme,
    settings: settings,
    tasbih: tasbih,
    feedback: feedback,
    quranLibrary: _quran,
    bookmarks: bookmarks,
  );
}

void main() {
  group('TasbihStore', () {
    test('the count survives a restart and never goes below zero', () {
      final storage = InMemoryStorage();
      final store = TasbihStore(storage)
        ..increment()
        ..increment()
        ..decrement();
      expect(TasbihStore(storage).count, 1);

      store
        ..reset()
        ..decrement();
      expect(store.count, 0);
      expect(TasbihStore(storage).count, 0);
    });

    test('ignores a malformed stored count', () {
      for (final raw in ['x', '-4', '']) {
        final storage = InMemoryStorage()..values['tasbih.count'] = raw;
        expect(TasbihStore(storage).count, 0, reason: raw);
      }
    });
  });

  group('BookmarkStore', () {
    test('keeps bookmarks newest first across a restart', () {
      final storage = InMemoryStorage();
      BookmarkStore(storage)
        ..toggle((surah: 1, ayah: 2))
        ..toggle((surah: 112, ayah: 1))
        ..toggle((surah: 1, ayah: 5))
        ..toggle((surah: 112, ayah: 1));

      expect(BookmarkStore(storage).bookmarks, [
        (surah: 1, ayah: 5),
        (surah: 1, ayah: 2),
      ]);
    });

    test('undoing a removal puts it back in place', () {
      final store = BookmarkStore(InMemoryStorage())
        ..insert((surah: 1, ayah: 1))
        ..insert((surah: 1, ayah: 2))
        ..insert((surah: 1, ayah: 3));
      final index = store.remove((surah: 1, ayah: 2));
      store.insert((surah: 1, ayah: 2), index);
      expect(store.bookmarks.map((r) => r.ayah), [3, 2, 1]);
      expect(store.remove((surah: 9, ayah: 9)), -1);
    });

    test('drops malformed and repeated stored values', () {
      final storage = InMemoryStorage()
        ..values['quran.bookmarks'] = '1:2,nope,3:,1:2,112:4';
      expect(BookmarkStore(storage).bookmarks, [
        (surah: 1, ayah: 2),
        (surah: 112, ayah: 4),
      ]);
    });
  });

  test('surah search ignores transliteration marks and punctuation', () {
    expect(foldLatin('Al-Fātiḥah'), 'alfatihah');
    expect(foldLatin('al fatihah'), 'alfatihah');
    expect(foldLatin('Āli ‘Imrān'), 'aliimran');
  });

  testWidgets('tapping counts, −1 takes one back, Ulang resets', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());

    final area = find.byKey(const ValueKey('tasbih-area'));
    for (var i = 0; i < 3; i++) {
      await tester.tap(area);
    }
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    expect(h.feedback.counts, [1, 2, 3]);

    await tester.tap(find.bySemanticsLabel('Kurangi satu hitungan'));
    await tester.pump();
    expect(h.tasbih.count, 2);

    await tester.tap(find.bySemanticsLabel('Ulang dari nol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(h.tasbih.count, 2, reason: 'cancel keeps the count');

    await tester.tap(find.bySemanticsLabel('Ulang dari nol'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Ulang'));
    await tester.pumpAndSettle();
    expect(h.tasbih.count, 0);
    expect(find.text('0'), findsOneWidget);
    expect(h.feedback.steps, 2);
  });

  Future<void> openQuran(WidgetTester tester, _Harness h) async {
    await tester.pumpWidget(h.app());
    await tester.tap(find.byKey(const ValueKey('tab-quran')));
    await tester.pumpAndSettle();
  }

  testWidgets('bookmark an ayah from search, then find it on the tab', (
    tester,
  ) async {
    final h = _Harness();
    await openQuran(tester, h);
    expect(find.textContaining('Belum ada ayat'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Cari surah atau ayat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ikhlas');
    await tester.pump();
    expect(find.text('112. Al-Ikhlāṣ'), findsOneWidget);
    expect(find.text('1. Al-Fātiḥah'), findsNothing);

    await tester.enterText(find.byType(TextField), '112:3');
    await tester.pump();
    await tester.tap(find.text('Al-Ikhlāṣ 112:3'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bookmark-toggle-112:3')));
    await tester.pump();
    expect(h.bookmarks.bookmarks, [(surah: 112, ayah: 3)]);
    expect(find.text('1 ayat ditandai di surah ini'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Al-Ikhlāṣ 112:3'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Ikhlas · 1 ditandai'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('1 AYAT DITANDAI'), findsOneWidget);
    expect(find.text('Al-Ikhlāṣ 112:3'), findsOneWidget);
  });

  testWidgets('swiping a bookmark away removes it, Urungkan restores it', (
    tester,
  ) async {
    final h = _Harness();
    h.bookmarks
      ..insert((surah: 1, ayah: 2))
      ..insert((surah: 112, ayah: 1));
    await openQuran(tester, h);
    expect(find.text('2 AYAT DITANDAI'), findsOneWidget);

    await tester.drag(find.text('Al-Fātiḥah 1:2'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(h.bookmarks.bookmarks, [(surah: 112, ayah: 1)]);
    expect(find.text('Penanda 1:2 dihapus'), findsOneWidget);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();
    expect(h.bookmarks.bookmarks, [(surah: 112, ayah: 1), (surah: 1, ayah: 2)]);
  });

  testWidgets('a bookmark opens the reader at its ayah', (tester) async {
    final h = _Harness();
    h.bookmarks.insert((surah: 1, ayah: 6));
    await openQuran(tester, h);

    await tester.tap(find.text('Al-Fātiḥah 1:6'));
    await tester.pumpAndSettle();
    expect(find.text('1. Al-Fātiḥah'), findsOneWidget);
    expect(find.text('Fatihah 6'), findsOneWidget);
    expect(find.byTooltip('Hapus penanda'), findsOneWidget);
  });

  group('SettingsStore', () {
    test('choices survive a restart', () {
      final storage = InMemoryStorage();
      final store = SettingsStore(storage);
      store.restoreTheme()
        ..select('lazuardi')
        ..mode = AppThemeMode.dark;
      store.restoreSettings()
        ..vibrate = false
        ..arabicSize = ArabicSize.large;

      final again = SettingsStore(storage);
      final theme = again.restoreTheme();
      final settings = again.restoreSettings();
      expect(theme.selectedTheme.id, 'lazuardi');
      expect(theme.mode, AppThemeMode.dark);
      expect(settings.vibrate, isFalse);
      expect(settings.arabicSize, ArabicSize.large);
    });

    test('keeps defaults for unknown stored values', () {
      final storage = InMemoryStorage()
        ..values.addAll({
          'settings.theme': 'gone',
          'settings.mode': 'neon',
          'settings.vibrate': 'maybe',
          'settings.arabicSize': 'huge',
        });
      final store = SettingsStore(storage);
      expect(store.restoreTheme().mode, AppThemeMode.system);
      final settings = store.restoreSettings();
      expect(settings.vibrate, isTrue);
      expect(settings.arabicSize, ArabicSize.medium);
    });
  });

  testWidgets('with vibration off, counting is silent', (tester) async {
    final h = _Harness();
    h.settings.vibrate = false;
    await tester.pumpWidget(h.app());
    await tester.tap(find.byKey(const ValueKey('tasbih-area')));
    await tester.pump();
    expect(h.tasbih.count, 1);
    expect(h.feedback.counts, isEmpty);
  });

  testWidgets('the Pengaturan tab changes and keeps choices', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.app());
    await tester.tap(find.byKey(const ValueKey('tab-pengaturan')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gelap'));
    await tester.tap(find.text('Mati'));
    await tester.tap(find.text('Besar'));
    await tester.pump();
    expect(h.theme.mode, AppThemeMode.dark);
    expect(h.settings.vibrate, isFalse);
    expect(h.settings.arabicSize, ArabicSize.large);
    expect(h.storage.values['settings.mode'], 'dark');
    expect(h.storage.values['settings.arabicSize'], 'large');
  });
}
