import 'dzikir_collection.dart';
import 'dzikir_entry.dart';
import 'dzikir_progress.dart';

/// What a single count did. The UI maps each event to haptics and motion.
enum DzikirEvent {
  /// A plain count.
  counted,

  /// Every [DzikirSession.milestoneEvery] counts within an entry.
  milestone,

  /// The current entry reached its target; the session moved to the next.
  entryCompleted,

  /// The last target was reached.
  sessionCompleted,

  /// A count after a sequence finished. Nothing changed.
  ignored,
}

/// Counts through a collection. Pure state: no timers, storage or haptics.
///
/// There is deliberately no undo: progress only moves forward, and every
/// count can be persisted through [progress].
final class DzikirSession {
  /// A sequence such as dzikir pagi. Restores [resume] when it still applies
  /// (see [canResume]).
  DzikirSession(this.collection, {DzikirProgress? resume, DateTime? now})
    : _openEnded = false {
    _restore(resume, now ?? DateTime.now());
  }

  /// Free tasbih on one phrase. Unlike a sequence it keeps counting after the
  /// target, which only fires [DzikirEvent.sessionCompleted] once.
  DzikirSession.free(DzikirEntry entry, {DzikirProgress? resume, DateTime? now})
    : collection = DzikirCollection(
        id: freeCollectionId(entry.text.id),
        title: entry.text.latin,
        kind: DzikirCollectionKind.presets,
        entries: [entry],
      ),
      _openEnded = true {
    _restore(resume, now ?? DateTime.now());
  }

  static const milestoneEvery = 33;

  /// Unwindowed sequences (ba'da shalat) belong to one prayer, so a pause
  /// longer than this starts over.
  static const shortSessionResumeLimit = Duration(hours: 1);

  static String freeCollectionId(String textId) => 'free:$textId';

  final DzikirCollection collection;
  final bool _openEnded;

  int _entryIndex = 0;
  int _count = 0;
  bool _complete = false;

  int get entryIndex => _entryIndex;
  int get count => _count;
  bool get isComplete => _complete;
  DzikirEntry get currentEntry => collection.entries[_entryIndex];

  /// Entries fully done, for "6 dari 15".
  int get completedEntries =>
      _complete && !_openEnded ? collection.entries.length : _entryIndex;

  DzikirEvent increment() {
    if (_complete && !_openEnded) return DzikirEvent.ignored;

    _count++;
    final target = currentEntry.target;
    if (target != null && _count == target) {
      if (_openEnded || _entryIndex == collection.entries.length - 1) {
        _complete = true;
        return DzikirEvent.sessionCompleted;
      }
      _entryIndex++;
      _count = 0;
      return DzikirEvent.entryCompleted;
    }
    return _count % milestoneEvery == 0
        ? DzikirEvent.milestone
        : DzikirEvent.counted;
  }

  /// A snapshot to persist, or null once a sequence is finished (clear the
  /// stored progress then).
  DzikirProgress? progress({DateTime? now}) {
    if (_complete && !_openEnded) return null;
    return DzikirProgress(
      collectionId: collection.id,
      entryIndex: _entryIndex,
      count: _count,
      updatedAt: now ?? DateTime.now(),
    );
  }

  /// Whether [progress] may continue this session at [now]:
  /// - windowed sequences (pagi, petang) and free tasbih: same calendar day;
  /// - other sequences (ba'da shalat): within [shortSessionResumeLimit].
  bool canResume(DzikirProgress progress, DateTime now) {
    if (progress.collectionId != collection.id) return false;
    if (progress.entryIndex < 0 ||
        progress.entryIndex >= collection.entries.length ||
        progress.count < 0) {
      return false;
    }
    final target = collection.entries[progress.entryIndex].target;
    if (!_openEnded && target != null && progress.count >= target) {
      return false;
    }

    final then = progress.updatedAt;
    final sameDay =
        then.year == now.year && then.month == now.month && then.day == now.day;
    if (_openEnded || collection.window != null) return sameDay;
    final age = now.difference(then);
    return !age.isNegative && age <= shortSessionResumeLimit;
  }

  void _restore(DzikirProgress? progress, DateTime now) {
    if (progress == null || !canResume(progress, now)) return;
    _entryIndex = progress.entryIndex;
    _count = progress.count;
    final target = currentEntry.target;
    _complete = _openEnded && target != null && _count >= target;
  }
}
