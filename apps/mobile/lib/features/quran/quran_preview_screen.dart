import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'quran_store.dart';
import 'sample_surahs.dart';

/// Qur'an tab, on sample surahs until the verified mushaf lands. One block
/// per ayah: Arabic, its translation when there is one, and a row with the
/// ayah's address and a bookmark.
///
/// The ayah on the reading line stays fully lit and the rest fade, so the
/// eye keeps its place. Where reading stops is saved and the tab reopens
/// there.
class QuranPreviewScreen extends StatefulWidget {
  const QuranPreviewScreen({super.key, required this.store});

  final QuranStore store;

  @override
  State<QuranPreviewScreen> createState() => _QuranPreviewScreenState();
}

class _QuranPreviewScreenState extends State<QuranPreviewScreen> {
  /// Where the reading line sits below the top of the screen.
  static const _readingLine = 140.0;

  final _scroll = ScrollController();
  final _keys = <AyahRef, GlobalKey>{
    for (final surah in sampleSurahs)
      for (var a = 1; a <= surah.ayat.length; a++)
        (surah: surah.number, ayah: a): GlobalKey(),
  };
  late AyahRef _focused = widget.store.lastRead ?? _keys.keys.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToLastRead());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToLastRead() {
    final context = _keys[widget.store.lastRead]?.currentContext;
    if (context == null || !mounted) return;
    Scrollable.ensureVisible(context, alignment: 0.2);
  }

  /// The ayah under the reading line: the last one whose top has passed it.
  AyahRef _ayahAtReadingLine() {
    final line = MediaQuery.paddingOf(context).top + _readingLine;
    var found = _keys.keys.first;
    for (final MapEntry(:key, :value) in _keys.entries) {
      final box = value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= line) found = key;
    }
    return found;
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final ayah = _ayahAtReadingLine();
      if (ayah != _focused) setState(() => _focused = ayah);
    } else if (notification is ScrollEndNotification) {
      widget.store.lastRead = _focused;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final store = widget.store;
    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                // A column rather than a lazy list: every ayah has a key to
                // measure and to jump to. The full mushaf will need paging.
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    padding.top + 96,
                    24,
                    padding.bottom + 32,
                  ),
                  child: Column(
                    children: [
                      for (final surah in sampleSurahs) ...[
                        _SurahHeader(name: surah.name, meaning: surah.meaning),
                        for (final (i, text) in surah.ayat.indexed)
                          if ((surah: surah.number, ayah: i + 1) case final ref)
                            _AyahBlock(
                              key: _keys[ref],
                              ref: ref,
                              arabic: text,
                              focused: _focused == ref,
                              bookmarked: store.isBookmarked(ref),
                              onBookmark: () => store.toggleBookmark(ref),
                            ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: padding.top + 8,
              left: 16,
              right: 16,
              child: _ReaderBar(lastRead: store.lastRead),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.name, required this.meaning});

  final String name;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    final title = TextStyler()
        .style(AppText.title.mix())
        .color(AppColors.inkPrimary());
    final subtitle = TextStyler()
        .style(AppText.translation.mix())
        .color(AppColors.inkSecondary());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(children: [title(name), subtitle(meaning)]),
    );
  }
}

class _AyahBlock extends StatelessWidget {
  const _AyahBlock({
    super.key,
    required this.ref,
    required this.arabic,
    required this.focused,
    required this.bookmarked,
    required this.onBookmark,
  });

  final AyahRef ref;
  final String arabic;
  final bool focused;
  final bool bookmarked;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final address = TextStyler()
        .style(AppText.caption.mix())
        .letterSpacing(0.5)
        .color(AppColors.inkMuted());
    final accent = AppColors.accent.resolve(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: focused ? 1 : 0.4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border.resolve(context)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    // No-break space keeps the marker with its ayah.
                    TextSpan(text: '$arabic '),
                    TextSpan(
                      text: ayahMarker(ref.ayah),
                      style: TextStyle(color: accent),
                    ),
                  ],
                ),
                style: AppText.ayah
                    .resolve(context)
                    .copyWith(color: AppColors.inkAyah.resolve(context)),
                textAlign: TextAlign.start,
                textDirection: TextDirection.rtl,
              ),
              // The translation goes here once the verified one is bundled.
              Row(
                children: [
                  address('${ref.surah}:${ref.ayah}'),
                  const Spacer(),
                  IconButton(
                    tooltip: bookmarked ? 'Hapus tanda ayat' : 'Tandai ayat',
                    onPressed: onBookmark,
                    icon: AppIcon(
                      bookmarked ? AppGlyph.bookmarkFilled : AppGlyph.bookmark,
                      size: 20,
                      color: bookmarked
                          ? accent
                          : AppColors.inkMuted.resolve(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

/// End-of-ayah marker in ornate parentheses with Arabic-Indic digits,
/// e.g. ﴿١٢﴾. Written in logical (RTL) order.
String ayahMarker(int number) {
  final digits = number
      .toString()
      .split('')
      .map((d) => _arabicDigits[int.parse(d)])
      .join();
  return '﴿$digits﴾';
}

class _ReaderBar extends StatelessWidget {
  const _ReaderBar({required this.lastRead});

  final AyahRef? lastRead;

  @override
  Widget build(BuildContext context) {
    final label = TextStyler()
        .style(AppText.label.mix())
        .color(AppColors.inkPrimary());
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());

    String surahName(int number) {
      for (final surah in sampleSurahs) {
        if (surah.number == number) return surah.name;
      }
      return 'Surah $number';
    }

    final last = lastRead;
    return GlassSurface(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label('Pratinjau pembaca'),
                caption(
                  last == null
                      ? 'Contoh surah · mushaf lengkap menyusul'
                      : 'Terakhir dibaca · ${surahName(last.surah)} '
                            '${last.surah}:${last.ayah}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
