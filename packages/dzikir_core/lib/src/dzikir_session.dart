import 'dzikir_collection.dart';
import 'dzikir_entry.dart';
import 'dzikir_progress.dart';

/// What a single count did. The UI maps each event to haptics and motion.
enum DzikirEvent {
  /// A plain count.
  counted,

  /// Every [DzikirSession.milestoneEvery] counts within an entry.
  milestone,

  /// The current entry reached its target, or was already at it; the
  /// session moved to the next.
  entryCompleted,

  /// The last target was reached.
  sessionCompleted,

  /// A count after a sequence finished. Nothing changed.
  ignored,
}

/// Counts through a collection. Pure state: no timers, storage or haptics.
///
/// Counting moves forward on its own. A sequence can also be stepped through
/// by hand ([previous], [next]) and a stray count taken back ([decrement]);
/// each entry keeps its own count, and every change can be persisted through
/// [progress].
final class DzikirSession {
  /// A sequence such as dzikir pagi. Restores [resume] when it still applies
  /// (see [canResume]).
  DzikirSession(this.collection, {DzikirProgress? resume, DateTime? now})
    : _openEnded = false,
      _counts = List.filled(collection.entries.length, 0) {
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
      _openEnded = true,
      _counts = [0] {
    _restore(resume, now ?? DateTime.now());
  }

  static const milestoneEvery = 33;

  /// Unwindowed sequences (ba'da shalat) belong to one prayer, so a pause
  /// longer than this starts over.
  static const shortSessionResumeLimit = Duration(hours: 1);

  static String freeCollectionId(String textId) => 'free:$textId';

  final DzikirCollection collection;
  final bool _openEnded;

  final List<int> _counts;
  int _entryIndex = 0;
  bool _complete = false;

  int get entryIndex => _entryIndex;
  int get count => _counts[_entryIndex];
  bool get isComplete => _complete;
  DzikirEntry get currentEntry => collection.entries[_entryIndex];

  bool get _isLast => _entryIndex == collection.entries.length - 1;

  /// Whether anything was counted or stepped through yet.
  bool get hasStarted => _entryIndex > 0 || _counts.any((c) => c > 0);

  /// Entries at their target, for "6 dari 15". Entries skipped with [next]
  /// don't count.
  int get completedEntries {
    if (_complete && !_openEnded) return collection.entries.length;
    var done = 0;
    for (final (i, entry) in collection.entries.indexed) {
      final target = entry.target;
      if (target != null && _counts[i] >= target) done++;
    }
    return done;
  }

  bool get canGoBack => !_openEnded && !_complete && _entryIndex > 0;
  bool get canGoForward => !_openEnded && !_complete && !_isLast;
  bool get canDecrement => !(_complete && !_openEnded) && count > 0;

  DzikirEvent increment() {
    if (_complete && !_openEnded) return DzikirEvent.ignored;

    final target = currentEntry.target;
    // Stepped back onto an entry that is already done: the next count moves
    // on rather than overshooting its target.
    if (!_openEnded && target != null && count >= target) return _advance();

    _counts[_entryIndex]++;
    if (target != null && count == target) {
      if (_openEnded) {
        _complete = true;
        return DzikirEvent.sessionCompleted;
      }
      return _advance();
    }
    return count % milestoneEvery == 0
        ? DzikirEvent.milestone
        : DzikirEvent.counted;
  }

  DzikirEvent _advance() {
    if (_isLast) {
      _complete = true;
      return DzikirEvent.sessionCompleted;
    }
    _entryIndex++;
    return DzikirEvent.entryCompleted;
  }

  /// Takes back one count in the current entry. Never crosses into the
  /// previous entry: that is [previous]. Returns whether anything changed.
  bool decrement() {
    if (!canDecrement) return false;
    _counts[_entryIndex]--;
    final target = currentEntry.target;
    // Free tasbih may cross its target again and should say so again.
    if (_openEnded && target != null && count < target) _complete = false;
    return true;
  }

  /// Back to the previous entry of a sequence, its count as it was.
  bool previous() {
    if (!canGoBack) return false;
    _entryIndex--;
    return true;
  }

  /// On to the next entry of a sequence, keeping this one's count. Not past
  /// the last entry: finishing a sequence takes reaching its target.
  bool next() {
    if (!canGoForward) return false;
    _entryIndex++;
    return true;
  }

  /// A snapshot to persist, or null once a sequence is finished (clear the
  /// stored progress then).
  DzikirProgress? progress({DateTime? now}) {
    if (_complete && !_openEnded) return null;
    return DzikirProgress(
      collectionId: collection.id,
      entryIndex: _entryIndex,
      count: count,
      updatedAt: now ?? DateTime.now(),
      counts: _openEnded ? null : List.unmodifiable(_counts),
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
    final counts = progress.counts;
    if (counts != null) {
      if (_openEnded ||
          counts.length != collection.entries.length ||
          counts.any((c) => c < 0) ||
          counts[progress.entryIndex] != progress.count) {
        return false;
      }
    } else {
      // Older progress without per-entry counts was always mid-entry.
      final target = collection.entries[progress.entryIndex].target;
      if (!_openEnded && target != null && progress.count >= target) {
        return false;
      }
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
    if (progress.counts case final counts?) {
      _counts.setAll(0, counts);
    } else {
      // Entries before the saved one were finished to reach it.
      for (var i = 0; i < _entryIndex; i++) {
        _counts[i] = collection.entries[i].target ?? 0;
      }
      _counts[_entryIndex] = progress.count;
    }
    final target = currentEntry.target;
    _complete = _openEnded && target != null && count >= target;
  }
}
