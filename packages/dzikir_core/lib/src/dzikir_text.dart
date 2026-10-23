/// One recitation's text, shared by every collection that uses it
/// (e.g. Ayat Kursi appears in pagi, petang and ba'da shalat).
final class DzikirText {
  const DzikirText({
    required this.id,
    required this.arabic,
    required this.latin,
    required this.translation,
  });

  factory DzikirText.fromJson(String id, Map<String, Object?> json) {
    String field(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('texts.$id.$key must be a non-empty string');
      }
      return value;
    }

    return DzikirText(
      id: id,
      arabic: field('arabic'),
      latin: field('latin'),
      translation: field('translation'),
    );
  }

  final String id;
  final String arabic;
  final String latin;

  /// Indonesian meaning.
  final String translation;

  /// Arabic letters only, without harakat, tatweel or punctuation. Used to
  /// judge how much screen a text needs regardless of its vowel marks.
  int get letterCount => arabic.runes.where(_isArabicLetter).length;

  static bool _isArabicLetter(int rune) =>
      (rune >= 0x0621 && rune <= 0x063A) ||
      (rune >= 0x0641 && rune <= 0x064A) ||
      (rune >= 0x0671 && rune <= 0x06D3);
}
