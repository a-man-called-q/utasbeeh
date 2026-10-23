import 'package:dzikir_core/dzikir_core.dart';
import 'package:test/test.dart';

DzikirText _text(String id) =>
    DzikirText(id: id, arabic: 'سُبْحَانَ اللَّهِ', latin: id, translation: id);

DzikirEntry _entry(String id, int? target) =>
    DzikirEntry(text: _text(id), target: target, source: 'test');

DzikirCollection _sequence({DzikirWindow? window}) => DzikirCollection(
  id: 'seq',
  title: 'Sequence',
  kind: DzikirCollectionKind.sequence,
  window: window,
  entries: [_entry('a', 2), _entry('b', 1), _entry('c', 100)],
);

final _now = DateTime(2026, 10, 22, 6, 0);

void main() {
  group('sequence', () {
    test('advances through entries and completes once', () {
      final session = DzikirSession(_sequence(), now: _now);

      expect(session.increment(), DzikirEvent.counted);
      expect(session.increment(), DzikirEvent.entryCompleted);
      expect(session.currentEntry.text.id, 'b');
      expect(session.count, 0);

      expect(session.increment(), DzikirEvent.entryCompleted);
      expect(session.completedEntries, 2);

      final events = [for (var i = 0; i < 100; i++) session.increment()];
      expect(events.last, DzikirEvent.sessionCompleted);
      expect(session.isComplete, isTrue);
      expect(session.completedEntries, 3);

      expect(session.increment(), DzikirEvent.ignored);
      expect(session.progress(now: _now), isNull);
    });

    test('fires a milestone every 33 counts within an entry', () {
      final session = DzikirSession(_sequence(), now: _now)
        ..increment()
        ..increment()
        ..increment();
      expect(session.currentEntry.text.id, 'c');

      final events = [for (var i = 0; i < 99; i++) session.increment()];
      final milestones = [
        for (final (i, e) in events.indexed)
          if (e == DzikirEvent.milestone) i + 1,
      ];
      expect(milestones, [33, 66, 99]);
    });
  });

  group('stepping and taking back', () {
    test('previous and next keep each entry\'s count', () {
      final session = DzikirSession(_sequence(), now: _now)..increment();
      expect(session.canGoBack, isFalse);
      expect(session.previous(), isFalse);

      expect(session.next(), isTrue);
      expect(session.currentEntry.text.id, 'b');
      expect(session.count, 0);
      expect(session.completedEntries, 0, reason: 'a was skipped at 1/2');

      expect(session.previous(), isTrue);
      expect(session.currentEntry.text.id, 'a');
      expect(session.count, 1);
    });

    test('next stops at the last entry; finishing takes the target', () {
      final session = DzikirSession(_sequence(), now: _now)
        ..next()
        ..next();
      expect(session.currentEntry.text.id, 'c');
      expect(session.canGoForward, isFalse);
      expect(session.next(), isFalse);
      expect(session.isComplete, isFalse);
    });

    test('counting on an entry already done moves on without overshooting', () {
      final session = DzikirSession(_sequence(), now: _now)
        ..increment()
        ..increment();
      expect(session.currentEntry.text.id, 'b');

      session.previous();
      expect(session.count, 2);
      expect(session.increment(), DzikirEvent.entryCompleted);
      expect(session.currentEntry.text.id, 'b');
      expect(session.completedEntries, 1);
    });

    test('decrement takes back one count, never across entries', () {
      final session = DzikirSession(_sequence(), now: _now);
      expect(session.canDecrement, isFalse);
      expect(session.decrement(), isFalse);

      session
        ..increment()
        ..increment();
      expect(session.currentEntry.text.id, 'b');
      expect(session.decrement(), isFalse, reason: 'b has no counts yet');

      session.previous();
      expect(session.decrement(), isTrue);
      expect(session.count, 1);
      expect(session.completedEntries, 0);
    });

    test('free tasbih completes again after a count is taken back', () {
      final session = DzikirSession.free(_entry('x', 2), now: _now);
      expect(session.canGoBack || session.canGoForward, isFalse);

      session.increment();
      expect(session.increment(), DzikirEvent.sessionCompleted);
      expect(session.decrement(), isTrue);
      expect(session.isComplete, isFalse);
      expect(session.increment(), DzikirEvent.sessionCompleted);
    });

    test('progress keeps every entry\'s count', () {
      final first = DzikirSession(_sequence(), now: _now)
        ..increment()
        ..next()
        ..next()
        ..increment();
      final saved = DzikirProgress.fromJson(
        first.progress(now: _now)!.toJson(),
      );
      expect(saved.counts, [1, 0, 1]);

      final resumed = DzikirSession(_sequence(), resume: saved, now: _now);
      expect(resumed.currentEntry.text.id, 'c');
      expect(resumed.count, 1);
      resumed
        ..previous()
        ..previous();
      expect(resumed.count, 1);
    });

    test('progress saved before navigation treats earlier entries as done', () {
      final old = DzikirProgress(
        collectionId: 'seq',
        entryIndex: 2,
        count: 5,
        updatedAt: _now,
      );
      final session = DzikirSession(_sequence(), resume: old, now: _now);
      expect(session.count, 5);
      expect(session.completedEntries, 2);
    });
  });

  group('free tasbih', () {
    test('keeps counting after the target, completing only once', () {
      final session = DzikirSession.free(_entry('subhanallah', 33));

      final events = [for (var i = 0; i < 40; i++) session.increment()];
      expect(events[32], DzikirEvent.sessionCompleted);
      expect(
        events.where((e) => e == DzikirEvent.sessionCompleted),
        hasLength(1),
      );
      expect(session.count, 40);
      expect(session.progress(now: _now)?.count, 40);
    });

    test('open-ended target never completes', () {
      final session = DzikirSession.free(
        _entry('subhanallah', 33).withTarget(null),
      );
      final events = [for (var i = 0; i < 200; i++) session.increment()];
      expect(events, isNot(contains(DzikirEvent.sessionCompleted)));
      expect(events.where((e) => e == DzikirEvent.milestone), hasLength(6));
    });
  });

  group('resume', () {
    DzikirProgress progress({
      String id = 'seq',
      int entry = 2,
      int count = 40,
      DateTime? at,
    }) => DzikirProgress(
      collectionId: id,
      entryIndex: entry,
      count: count,
      updatedAt: at ?? _now,
    );

    test('windowed sequences resume within the same day', () {
      final collection = _sequence(
        window: const DzikirWindow(startMinute: 210, endMinute: 660),
      );
      final later = _now.add(const Duration(hours: 4));

      final resumed = DzikirSession(collection, resume: progress(), now: later);
      expect((resumed.entryIndex, resumed.count), (2, 40));

      final nextDay = DzikirSession(
        collection,
        resume: progress(),
        now: _now.add(const Duration(days: 1)),
      );
      expect((nextDay.entryIndex, nextDay.count), (0, 0));
    });

    test('unwindowed sequences resume only within an hour', () {
      final collection = _sequence();

      final soon = DzikirSession(
        collection,
        resume: progress(),
        now: _now.add(const Duration(minutes: 50)),
      );
      expect(soon.count, 40);

      final stale = DzikirSession(
        collection,
        resume: progress(),
        now: _now.add(const Duration(minutes: 61)),
      );
      expect(stale.count, 0);
    });

    test('rejects progress that does not fit the content', () {
      final collection = _sequence();
      for (final bad in [
        progress(id: 'other'),
        progress(entry: 3),
        progress(entry: 0, count: 2),
      ]) {
        final session = DzikirSession(collection, resume: bad, now: _now);
        expect((session.entryIndex, session.count), (0, 0));
      }
    });

    test('free tasbih past its target restores as complete', () {
      final entry = _entry('subhanallah', 33);
      final session = DzikirSession.free(
        entry,
        resume: progress(
          id: DzikirSession.freeCollectionId('subhanallah'),
          entry: 0,
          count: 35,
        ),
        now: _now,
      );
      expect(session.isComplete, isTrue);
      expect(session.increment(), DzikirEvent.counted);
      expect(session.count, 36);
    });

    test('progress round-trips through JSON', () {
      final original = progress();
      final copy = DzikirProgress.fromJson(original.toJson());
      expect(copy.toJson(), original.toJson());
    });
  });

  test('windows can cross midnight', () {
    const night = DzikirWindow(startMinute: 22 * 60, endMinute: 2 * 60);
    expect(night.contains(DateTime(2026, 1, 1, 23)), isTrue);
    expect(night.contains(DateTime(2026, 1, 1, 1)), isTrue);
    expect(night.contains(DateTime(2026, 1, 1, 3)), isFalse);
  });
}
