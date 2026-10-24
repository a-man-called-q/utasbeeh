import 'dart:io';

import 'package:quran_core/quran_core.dart';
import 'package:test/test.dart';

void main() {
  group('bundled mushaf', () {
    final library = QuranLibrary.parse(
      arabic: File('lib/content/quran-uthmani.txt').readAsStringSync(),
      translation: File('lib/content/en.pickthall.txt').readAsStringSync(),
    );

    test('holds every ayah of every surah', () {
      expect(library.surahs, hasLength(114));
      expect(library.surahs.fold<int>(0, (n, s) => n + s.ayat.length), 6236);
      expect(library.surah(2)!.ayat, hasLength(286));
      expect(library.surah(114)!.ayat, hasLength(6));
      expect(library.surah(1)!.ayat.first.translation, startsWith('In the'));
    });

    test('the basmalah heading comes off ayah 1, not the text', () {
      final basmalah = library.surah(1)!.ayat.first.arabic;
      String opening(int surah) =>
          withoutBasmalah(library.surah(surah)!.ayat.first.arabic, basmalah);

      expect(opening(2), 'الٓمٓ');
      expect(opening(95), isNot(contains('بِسْمِ')), reason: 'shadda form');
      expect(opening(97), isNot(contains('بِسْمِ')), reason: 'shadda form');
      expect(opening(9), library.surah(9)!.ayat.first.arabic);
      expect(library.surah(2)!.ayat.first.arabic, startsWith(basmalah));
      expect(library.surah(9)!.headedByBasmalah, isFalse);
    });
  });

  test('ayah addresses round-trip and reject anything else', () {
    expect(parseAyahRef(formatAyahRef((surah: 2, ayah: 255))), (
      surah: 2,
      ayah: 255,
    ));
    expect(parseAyahRef(' 36 : 1 '), (surah: 36, ayah: 1));
    for (final bad in ['', '2', '2:', ':5', 'a:b', '1:2:3']) {
      expect(parseAyahRef(bad), isNull, reason: bad);
    }
  });

  test('ayah markers use Arabic-Indic digits', () {
    expect(ayahMarker(7), '﴿٧﴾');
    expect(ayahMarker(286), '﴿٢٨٦﴾');
  });
}
