import 'surah_names.dart';

final class Ayah {
  const Ayah({
    required this.number,
    required this.arabic,
    required this.translation,
  });

  final int number;

  /// Tanzil Uthmani text, verbatim.
  final String arabic;
  final String translation;
}

final class Surah {
  const Surah({
    required this.number,
    required this.name,
    required this.meaning,
    required this.arabicName,
    required this.makki,
    required this.ayat,
  });

  final int number;
  final String name;

  /// Indonesian meaning of the name, e.g. "Pembuka".
  final String meaning;
  final String arabicName;
  final bool makki;
  final List<Ayah> ayat;

  /// Every surah but Al-Fātiḥah (where it is ayah 1) and At-Taubah opens with
  /// the basmalah, which a mushaf prints as a heading above ayah 1.
  bool get headedByBasmalah => number != 1 && number != 9;
}

/// The whole Qur'an: Tanzil's Uthmani text with an interim English
/// translation, bundled verbatim under `lib/content/` (see SOURCES.md
/// there) and parsed at startup.
final class QuranLibrary {
  QuranLibrary(this.surahs);

  /// Parses Tanzil "text with aya numbers" files (`surah|ayah|text`, `#`
  /// comments). Throws [FormatException] if either file does not hold every
  /// ayah of every surah.
  factory QuranLibrary.parse({
    required String arabic,
    required String translation,
  }) {
    final arabicAyat = _lines(arabic, 'arabic');
    final translated = _lines(translation, 'translation');
    return QuranLibrary([
      for (final (i, meta) in surahNames.indexed)
        Surah(
          number: i + 1,
          name: meta.name,
          meaning: meta.meaning,
          arabicName: meta.arabic,
          makki: meta.makki,
          ayat: [
            for (var a = 1; a <= meta.ayat; a++)
              Ayah(
                number: a,
                arabic: arabicAyat['${i + 1}|$a'] ?? _missing('arabic', i, a),
                translation:
                    translated['${i + 1}|$a'] ?? _missing('translation', i, a),
              ),
          ],
        ),
    ]);
  }

  /// Asset keys for an app that lists them under `flutter: assets:`.
  static const arabicAsset = 'packages/quran_core/content/quran-uthmani.txt';
  static const translationAsset =
      'packages/quran_core/content/en.pickthall.txt';

  /// Loads both files through [loadString], e.g. `rootBundle.loadString`.
  static Future<QuranLibrary> load(
    Future<String> Function(String asset) loadString,
  ) async {
    final (arabic, translation) = await (
      loadString(arabicAsset),
      loadString(translationAsset),
    ).wait;
    return QuranLibrary.parse(arabic: arabic, translation: translation);
  }

  final List<Surah> surahs;

  Surah? surah(int number) {
    for (final surah in surahs) {
      if (surah.number == number) return surah;
    }
    return null;
  }

  static Map<String, String> _lines(String source, String which) {
    final out = <String, String>{};
    for (final line in source.split('\n')) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final first = line.indexOf('|');
      final second = line.indexOf('|', first + 1);
      if (first < 0 || second < 0) {
        throw FormatException('Malformed $which line: $line');
      }
      out[line.substring(0, second)] = line.substring(second + 1).trimRight();
    }
    return out;
  }

  static Never _missing(String which, int surahIndex, int ayah) =>
      throw FormatException('No $which for ${surahIndex + 1}:$ayah');
}

/// Ayah 1 of most surahs carries the basmalah in Tanzil's text. For display
/// under a basmalah heading, the ayah without it; [basmalah] is Al-Fātiḥah
/// 1:1. Surahs 95 and 97 spell its first word with a shadda (joined to the
/// surah before in continuous recitation), so that is ignored when matching.
/// The stored text is never changed.
String withoutBasmalah(String ayah, String basmalah) {
  final words = ayah.split(' ');
  final opening = basmalah.split(' ');
  if (words.length <= opening.length) return ayah;
  final first = words.first.replaceFirst('ّ', '');
  final head = [first, ...words.sublist(1, opening.length)].join(' ');
  return head == basmalah ? words.sublist(opening.length).join(' ') : ayah;
}
