/// One recitation's text, shared by every collection that uses it
/// (e.g. Ayat Kursi appears in pagi, petang and ba'da shalat).
final class DzikirText {
  const DzikirText({
    required this.id,
    required this.arabic,
    required this.latin,
    required this.translation,
    this.segments = const [],
  });

  factory DzikirText.fromJson(String id, Map<String, Object?> json) {
    String field(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('texts.$id.$key must be a non-empty string');
      }
      return value;
    }

    final rawSegments = json['segments'] ?? const <Object?>[];
    if (rawSegments is! List) {
      throw FormatException('texts.$id.segments must be a list');
    }
    final text = DzikirText(
      id: id,
      arabic: field('arabic'),
      latin: field('latin'),
      translation: field('translation'),
      segments: [
        for (final (i, raw) in rawSegments.indexed)
          DzikirSegment.fromJson(
            raw is Map<String, Object?>
                ? raw
                : throw FormatException(
                    'texts.$id.segments[$i] must be an object',
                  ),
            'texts.$id.segments[$i]',
          ),
      ],
    );
    text._checkSegments();
    return text;
  }

  final String id;
  final String arabic;
  final String latin;

  /// Indonesian meaning.
  final String translation;

  /// The text split at its natural pauses, for reading one part at a time.
  /// Empty for short texts. Together the parts are exactly the full text.
  final List<DzikirSegment> segments;

  /// Segments must not drift from the full text: joined (whitespace aside)
  /// they spell the same Arabic and Latin, and the same translation when
  /// every part carries one.
  void _checkSegments() {
    if (segments.isEmpty) return;
    if (segments.length == 1) {
      throw FormatException('texts.$id: one segment is no split; drop it');
    }
    void same(String field, String full, Iterable<String> parts) {
      if (_squash(parts.join()) != _squash(full)) {
        throw FormatException('texts.$id.segments do not add up to $field');
      }
    }

    same('arabic', arabic, segments.map((s) => s.arabic));
    same('latin', latin, segments.map((s) => s.latin));
    final translations = segments.map((s) => s.translation).toList();
    if (translations.every((t) => t != null)) {
      same('translation', translation, translations.cast<String>());
    } else if (translations.any((t) => t != null)) {
      throw FormatException(
        'texts.$id.segments: give every part a translation, or none',
      );
    }
  }

  static String _squash(String s) => s.replaceAll(RegExp(r'\s+'), '');

  /// Arabic letters only, without harakat, tatweel or punctuation. Used to
  /// judge how much screen a text needs regardless of its vowel marks.
  int get letterCount => arabic.runes.where(_isArabicLetter).length;

  static bool _isArabicLetter(int rune) =>
      (rune >= 0x0621 && rune <= 0x063A) ||
      (rune >= 0x0641 && rune <= 0x064A) ||
      (rune >= 0x0671 && rune <= 0x06D3);
}

/// One part of a long text, read on its own screen.
final class DzikirSegment {
  const DzikirSegment({
    required this.arabic,
    required this.latin,
    this.translation,
    this.label,
  });

  factory DzikirSegment.fromJson(Map<String, Object?> json, String path) {
    String? optional(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('$path.$key must be a non-empty string');
      }
      return value;
    }

    final arabic = optional('arabic');
    final latin = optional('latin');
    if (arabic == null || latin == null) {
      throw FormatException('$path needs arabic and latin');
    }
    return DzikirSegment(
      arabic: arabic,
      latin: latin,
      translation: optional('translation'),
      label: optional('label'),
    );
  }

  final String arabic;
  final String latin;

  /// Null when the whole text's translation is a summary that can't be split,
  /// e.g. the three protective surahs.
  final String? translation;

  /// A name for the part, e.g. "Al-Ikhlas".
  final String? label;
}
