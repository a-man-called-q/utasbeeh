import 'dzikir_entry.dart';
import 'dzikir_window.dart';

enum DzikirCollectionKind {
  /// Recited in order, one entry after another (pagi, petang, ba'da shalat).
  sequence,

  /// A menu of phrases for free tasbih; the user picks one entry.
  presets,
}

final class DzikirCollection {
  const DzikirCollection({
    required this.id,
    required this.title,
    required this.kind,
    required this.entries,
    this.subtitle,
    this.window,
  });

  /// Stable id used to persist progress. Never rename.
  final String id;
  final String title;
  final String? subtitle;
  final DzikirCollectionKind kind;
  final List<DzikirEntry> entries;

  /// When the collection is suggested on the home screen, if ever.
  final DzikirWindow? window;
}
