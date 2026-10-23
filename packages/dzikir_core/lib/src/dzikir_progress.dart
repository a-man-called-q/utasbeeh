/// A snapshot of an unfinished session, small enough to persist after every
/// count so closing the app never loses a count.
final class DzikirProgress {
  const DzikirProgress({
    required this.collectionId,
    required this.entryIndex,
    required this.count,
    required this.updatedAt,
  });

  factory DzikirProgress.fromJson(Map<String, Object?> json) {
    final collectionId = json['collectionId'];
    final entryIndex = json['entryIndex'];
    final count = json['count'];
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    if (collectionId is! String ||
        entryIndex is! int ||
        count is! int ||
        updatedAt == null) {
      throw FormatException('Invalid dzikir progress: $json');
    }
    return DzikirProgress(
      collectionId: collectionId,
      entryIndex: entryIndex,
      count: count,
      updatedAt: updatedAt,
    );
  }

  final String collectionId;
  final int entryIndex;

  /// Count within the current entry.
  final int count;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'collectionId': collectionId,
    'entryIndex': entryIndex,
    'count': count,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
