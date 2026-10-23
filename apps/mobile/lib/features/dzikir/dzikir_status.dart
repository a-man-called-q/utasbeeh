import 'package:dzikir_core/dzikir_core.dart';

import 'dzikir_services.dart';

enum DzikirStatusKind { idle, inProgress, done }

/// Where a collection stands right now. Shared by the home card and the
/// dzikir list so both say the same thing.
class DzikirStatus {
  const DzikirStatus._(
    this.kind, {
    this.completed = 0,
    this.total = 0,
    this.completedAt,
  });

  factory DzikirStatus.of(
    DzikirCollection collection,
    DzikirServices services,
  ) {
    if (collection.kind == DzikirCollectionKind.presets) {
      return const DzikirStatus._(DzikirStatusKind.idle);
    }
    final now = services.clock();
    final session = DzikirSession(
      collection,
      resume: services.store.progressFor(collection.id),
      now: now,
    );
    if (session.entryIndex > 0 || session.count > 0) {
      return DzikirStatus._(
        DzikirStatusKind.inProgress,
        completed: session.completedEntries,
        total: collection.entries.length,
      );
    }
    final completedAt = services.store.completedAt(collection.id);
    if (completedAt != null &&
        completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day) {
      return DzikirStatus._(DzikirStatusKind.done, completedAt: completedAt);
    }
    return const DzikirStatus._(DzikirStatusKind.idle);
  }

  final DzikirStatusKind kind;
  final int completed;
  final int total;
  final DateTime? completedAt;

  /// 0–1 for a progress bar.
  double get fraction => total == 0 ? 0 : completed / total;

  /// One line under the collection title.
  String describe(DzikirCollection collection) => switch (kind) {
    DzikirStatusKind.inProgress => 'Lanjut · $completed dari $total',
    DzikirStatusKind.done when collection.window == null =>
      'Terakhir selesai ${_time(completedAt!)}',
    DzikirStatusKind.done => 'Selesai hari ini',
    DzikirStatusKind.idle => collection.subtitle ?? '',
  };

  /// "selesai", "sebagian" or "belum", for the daily summary.
  String get word => switch (kind) {
    DzikirStatusKind.done => 'selesai',
    DzikirStatusKind.inProgress => 'sebagian',
    DzikirStatusKind.idle => 'belum',
  };

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
}
