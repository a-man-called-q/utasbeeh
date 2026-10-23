import 'dart:io';

import 'package:dzikir_core/dzikir_core.dart';
import 'package:test/test.dart';

/// Guards the bundled content. A typo in an id, a missing source or a zero
/// target fails here instead of in the app.
void main() {
  final library = DzikirLibrary.parse(
    File('lib/content/dzikir.json').readAsStringSync(),
  );

  test('ships the v1 collections', () {
    expect(library.collections.map((c) => c.id), [
      'pagi',
      'petang',
      'bada_shalat',
      'tasbih_bebas',
    ]);
  });

  test('every read-mode text is split into parts', () {
    for (final collection in library.collections) {
      for (final entry in collection.entries) {
        if (entry.mode != DzikirMode.read) continue;
        expect(entry.text.segments, isNotEmpty, reason: entry.text.id);
      }
    }
  });

  test('every entry names its evidence', () {
    for (final collection in library.collections) {
      for (final entry in collection.entries) {
        expect(entry.source, isNotEmpty, reason: entry.text.id);
      }
    }
  });

  test("ba'da shalat totals 100 for tasbih, tahmid, takbir and tahlil", () {
    final entries = library.byId('bada_shalat')!.entries;
    final tail = entries.skip(entries.length - 4);
    expect(tail.map((e) => e.target).fold<int>(0, (a, b) => a + b!), 100);
  });

  group('mode heuristic on real texts', () {
    DzikirMode modeOf(String collectionId, String textId) => library
        .byId(collectionId)!
        .entries
        .firstWhere((e) => e.text.id == textId)
        .mode;

    test('long texts read', () {
      expect(modeOf('pagi', 'ayat_kursi'), DzikirMode.read);
      expect(modeOf('pagi', 'al_muawwidzat'), DzikirMode.read);
      expect(modeOf('pagi', 'ashbahna'), DzikirMode.read);
      expect(modeOf('pagi', 'sayyidul_istighfar'), DzikirMode.read);
      expect(modeOf('bada_shalat', 'la_mania'), DzikirMode.read);
    });

    test('short texts count', () {
      expect(modeOf('pagi', 'hasbiyallah'), DzikirMode.count);
      expect(modeOf('pagi', 'tahlil'), DzikirMode.count);
      expect(modeOf('pagi', 'subhanallah_wabihamdih'), DzikirMode.count);
      expect(modeOf('bada_shalat', 'subhanallah'), DzikirMode.count);
      expect(modeOf('petang', 'audzu_bikalimatillah'), DzikirMode.count);
    });
  });

  test('suggests pagi in the morning and petang after Ashar', () {
    expect(library.suggestedAt(DateTime(2026, 10, 22, 5, 0))?.id, 'pagi');
    expect(library.suggestedAt(DateTime(2026, 10, 22, 16, 30))?.id, 'petang');
    expect(library.suggestedAt(DateTime(2026, 10, 22, 12, 0)), isNull);
    expect(library.suggestedAt(DateTime(2026, 10, 22, 21, 0)), isNull);
  });
}
