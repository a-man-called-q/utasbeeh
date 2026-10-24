import 'package:design_system/design_system.dart';
import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/widgets.dart';
import 'package:tasbeeh/app.dart';
import 'package:tasbeeh/features/dzikir/dzikir_progress_store.dart';
import 'package:tasbeeh/features/dzikir/dzikir_services.dart';
import 'package:tasbeeh/features/quran/quran_store.dart';
import 'package:tasbeeh/features/settings/settings_store.dart';
import 'package:quran_core/quran_core.dart';

const shortText = DzikirText(
  id: 'short',
  arabic: 'سُبْحَانَ اللَّهِ',
  latin: 'Subhanallah',
  translation: 'Mahasuci Allah',
);

/// Over the read-mode threshold, so it renders with the done button.
final longText = DzikirText(
  id: 'long',
  arabic: List.filled(14, 'سُبْحَانَ اللَّهِ').join(' '),
  latin: 'Long recitation',
  translation: 'Bacaan panjang',
);

/// A text in two parts, read one sentence at a time.
const partedText = DzikirText(
  id: 'parted',
  arabic: 'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ',
  latin: 'Part one, part two',
  translation: 'Arti satu, arti dua',
  segments: [
    DzikirSegment(
      arabic: 'سُبْحَانَ اللَّهِ',
      latin: 'Part one,',
      translation: 'Arti satu,',
    ),
    DzikirSegment(
      arabic: 'وَالْحَمْدُ لِلَّهِ',
      latin: 'part two',
      translation: 'arti dua',
    ),
  ],
);

/// Two short surahs, so reader tests don't parse the whole mushaf.
final fixtureQuran = QuranLibrary([
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

DzikirEntry entry(DzikirText text, int? target) =>
    DzikirEntry(text: text, target: target, source: 'HR. Test');

final fixtureLibrary = DzikirLibrary(
  version: 1,
  reference: 'test',
  reviewed: false,
  collections: [
    DzikirCollection(
      id: 'pagi',
      title: 'Dzikir pagi',
      subtitle: 'Pagi',
      kind: DzikirCollectionKind.sequence,
      window: const DzikirWindow(startMinute: 210, endMinute: 660),
      entries: [entry(shortText, 2), entry(longText, 2), entry(shortText, 1)],
    ),
    DzikirCollection(
      id: 'petang',
      title: 'Dzikir petang',
      subtitle: 'Petang',
      kind: DzikirCollectionKind.sequence,
      window: const DzikirWindow(startMinute: 900, endMinute: 1140),
      entries: [entry(shortText, 1)],
    ),
    const DzikirCollection(
      id: 'bertahap',
      title: 'Bacaan bertahap',
      kind: DzikirCollectionKind.sequence,
      entries: [
        DzikirEntry(
          text: partedText,
          target: 2,
          source: 'HR. Test',
          modeOverride: DzikirMode.read,
        ),
      ],
    ),
    DzikirCollection(
      id: 'tasbih_bebas',
      title: 'Tasbih bebas',
      kind: DzikirCollectionKind.presets,
      entries: [entry(shortText, 33)],
    ),
  ],
);

class RecordingFeedback implements DzikirFeedback {
  final events = <DzikirEvent>[];

  var steps = 0;

  @override
  void onEvent(DzikirEvent event) => events.add(event);

  @override
  void onStep() => steps++;
}

class DzikirHarness {
  DzikirHarness({DateTime? now}) : now = now ?? DateTime(2026, 10, 23, 6);

  DateTime now;
  final store = InMemoryDzikirProgressStore();
  final feedback = RecordingFeedback();
  final awake = <bool>[];
  final quranBackend = InMemorySettingsBackend();
  late final quran = QuranStore(quranBackend);

  late final services = DzikirServices(
    library: fixtureLibrary,
    store: store,
    feedback: feedback,
    keepAwake: awake.add,
    clock: () => now,
  );

  Widget app({ThemeController? themeController}) => TasbeehApp(
    themeController:
        themeController ??
        ThemeController(mode: AppThemeMode.light, glassMode: GlassMode.solid),
    dzikirServices: services,
    quranLibrary: fixtureQuran,
    quranStore: quran,
  );
}
