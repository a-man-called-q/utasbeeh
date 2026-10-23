import 'package:design_system/design_system.dart';
import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/widgets.dart';
import 'package:tasbeeh/app.dart';
import 'package:tasbeeh/features/dzikir/dzikir_progress_store.dart';
import 'package:tasbeeh/features/dzikir/dzikir_services.dart';

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

  @override
  void onEvent(DzikirEvent event) => events.add(event);
}

class DzikirHarness {
  DzikirHarness({DateTime? now}) : now = now ?? DateTime(2026, 10, 23, 6);

  DateTime now;
  final store = InMemoryDzikirProgressStore();
  final feedback = RecordingFeedback();
  final awake = <bool>[];

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
  );
}
