/// A snapshot of an unfinished session, small enough to persist after every
/// count so closing the app never loses a count.
final class DzikirProgress {
  const DzikirProgress({
    required this.collectionId,
    required this.entryIndex,
    required this.count,
    required this.updatedAt,
    this.counts,
  });

  factory DzikirProgress.fromJson(Map<String, Object?> json) {
    final collectionId = json['collectionId'];
    final entryIndex = json['entryIndex'];
    final count = json['count'];
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    final counts = json['counts'];
    if (collectionId is! String ||
        entryIndex is! int ||
        count is! int ||
        updatedAt == null ||
        (counts != null && (counts is! List || counts.any((c) => c is! int)))) {
      throw FormatException('Invalid dzikir progress: $json');
    }
    return DzikirProgress(
      collectionId: collectionId,
      entryIndex: entryIndex,
      count: count,
      updatedAt: updatedAt,
      counts: counts == null ? null : List<int>.unmodifiable(counts as List),
    );
  }

  final String collectionId;
  final int entryIndex;

  /// Count within the current entry.
  final int count;
  final DateTime updatedAt;

  /// Every entry's count in a sequence, so stepping back finds earlier
  /// entries as they were. Null in free tasbih and in progress saved before
  /// sequences could be navigated (entries before [entryIndex] then count as
  /// done).
  final List<int>? counts;

  Map<String, Object?> toJson() => {
    'collectionId': collectionId,
    'entryIndex': entryIndex,
    'count': count,
    'updatedAt': updatedAt.toIso8601String(),
    'counts': ?counts,
  };
}
