import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:quran_core/quran_core.dart';

import 'bookmark_store.dart';
import 'reader_screen.dart';

/// Every surah, filtered as you type a name or number. Typing an address
/// such as 2:255 offers that ayah directly, the quickest way to bookmark it.
class SurahPickerScreen extends StatefulWidget {
  const SurahPickerScreen({
    super.key,
    required this.library,
    required this.store,
  });

  final QuranLibrary library;
  final BookmarkStore store;

  @override
  State<SurahPickerScreen> createState() => _SurahPickerScreenState();
}

class _SurahPickerScreenState extends State<SurahPickerScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(Surah surah, [int? ayah]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          library: widget.library,
          store: widget.store,
          surah: surah,
          startAyah: ayah,
        ),
      ),
    );
  }

  /// The ayah [query] addresses, if it is a valid `surah:ayah`.
  (Surah, int)? _address(String query) {
    final ref = parseAyahRef(query);
    if (ref == null) return null;
    final surah = widget.library.surah(ref.surah);
    if (surah == null || ref.ayah < 1 || ref.ayah > surah.ayat.length) {
      return null;
    }
    return (surah, ref.ayah);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // Bookmark counts change while a surah is open from here.
    listenable: Listenable.merge([_query, widget.store]),
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final query = _query.text.trim();
    final address = _address(query);
    final needle = foldLatin(query);
    final surahs = [
      for (final surah in widget.library.surahs)
        if (needle.isEmpty ||
            '${surah.number}' == needle ||
            foldLatin(surah.name).contains(needle) ||
            foldLatin(surah.meaning).contains(needle))
          surah,
    ];
    final bookmarked = <int, int>{};
    for (final ref in widget.store.bookmarks) {
      bookmarked.update(ref.surah, (n) => n + 1, ifAbsent: () => 1);
    }

    final overline = TextStyler()
        .style(AppText.overline.mix())
        .color(AppColors.inkSecondary());
    final ink = AppColors.inkPrimary.resolve(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.maybePop(context),
                    icon: AppIcon(AppGlyph.chevronLeft, color: ink),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        if (address case (final surah, final ayah)?) {
                          _open(surah, ayah);
                        }
                      },
                      style: AppText.body.resolve(context).copyWith(color: ink),
                      decoration: InputDecoration(
                        hintText: 'Nama surah, nomor, atau 2:255',
                        hintStyle: AppText.body
                            .resolve(context)
                            .copyWith(
                              color: AppColors.inkMuted.resolve(context),
                            ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (address case (final surah, final ayah)?) ...[
                    overline('AYAT'),
                    const SizedBox(height: 12),
                    AppListRow(
                      first: true,
                      title: '${surah.name} ${surah.number}:$ayah',
                      subtitle: 'Buka di ayat ini',
                      highlighted: true,
                      onPress: () => _open(surah, ayah),
                    ),
                    const SizedBox(height: 32),
                  ],
                  if (address == null || surahs.isNotEmpty) ...[
                    overline('SURAH'),
                    const SizedBox(height: 12),
                  ],
                  for (final (i, surah) in surahs.indexed)
                    AppListRow(
                      first: i == 0,
                      title: '${surah.number}. ${surah.name}',
                      subtitle: switch (bookmarked[surah.number]) {
                        final n? => '${surah.meaning} · $n ditandai',
                        null => '${surah.meaning} · ${surah.ayat.length} ayat',
                      },
                      highlighted: bookmarked.containsKey(surah.number),
                      trailing: _arabicName(surah.arabicName),
                      onPress: () => _open(surah),
                    ),
                  if (surahs.isEmpty && address == null)
                    TextStyler()
                        .style(AppText.body.mix())
                        .color(AppColors.inkSecondary())(
                      'Tidak ada surah yang cocok.',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _arabicName(String name) => TextStyler()
      .style(AppText.ayah.mix())
      .fontSize(20)
      .height(1.4)
      .color(AppColors.inkAyah())
      .textDirection(TextDirection.rtl)(name);
}

/// Lower-cased with transliteration marks and punctuation dropped, so
/// "al fatihah", "Alfatihah" and "Al-Fātiḥah" all match.
@visibleForTesting
String foldLatin(String text) {
  const plain = {
    'ā': 'a',
    'ī': 'i',
    'ū': 'u',
    'ḥ': 'h',
    'ṣ': 's',
    'ḍ': 'd',
    'ṭ': 't',
    'ẓ': 'z',
  };
  final out = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    final mapped = plain[char] ?? char;
    if (RegExp(r'[a-z0-9]').hasMatch(mapped)) out.write(mapped);
  }
  return out.toString();
}
