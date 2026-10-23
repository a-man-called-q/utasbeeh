import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'quran_library.dart';
import 'quran_store.dart';

/// One surah, ayah by ayah: Arabic with its marker, the translation, and a
/// row with the ayah's address and a bookmark.
///
/// The ayah on the reading line stays fully lit and the rest fade, so the
/// eye keeps its place; where reading stops is saved as the last-read ayah.
class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({
    super.key,
    required this.library,
    required this.store,
    required this.surah,
    this.startAyah,
  });

  final QuranLibrary library;
  final QuranStore store;
  final Surah surah;

  /// Ayah to open at, e.g. the last-read one or a bookmark.
  final int? startAyah;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  /// Where the reading line sits below the top of the screen: well under
  /// the floating bar, so the lit ayah is never hidden behind it.
  static const _readingLine = 240.0;

  final _scroll = ScrollController();
  late final _keys = [for (final _ in widget.surah.ayat) GlobalKey()];
  late int _focused = (widget.startAyah ?? 1).clamp(
    1,
    widget.surah.ayat.length,
  );

  Surah get surah => widget.surah;

  @override
  void initState() {
    super.initState();
    if (widget.startAyah case final ayah? when ayah > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpTo(ayah));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The list builds lazily, so an ayah far down has no widget to scroll to
  /// yet: jump to where it should be, let it build, then settle on it.
  Future<void> _jumpTo(int ayah) async {
    for (var attempt = 0; attempt < 10 && mounted; attempt++) {
      final context = _keys[ayah - 1].currentContext;
      if (context != null && context.mounted) {
        Scrollable.ensureVisible(context, alignment: 0.22);
        return;
      }
      final position = _scroll.position;
      final guess = position.maxScrollExtent * (ayah - 1) / surah.ayat.length;
      _scroll.jumpTo(math.min(guess, position.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// The ayah under the reading line: the last built one whose top has
  /// passed it.
  int _ayahAtReadingLine() {
    final line = MediaQuery.paddingOf(context).top + _readingLine;
    var found = 1;
    for (final (i, key) in _keys.indexed) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= line) found = i + 1;
    }
    return found;
  }

  /// Scroll notifications fire before the frame lays out the new offset, so
  /// positions are measured once it has.
  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final save = notification is ScrollEndNotification;
      WidgetsBinding.instance
        ..addPostFrameCallback((_) => _refocus(save: save))
        ..scheduleFrame();
    }
    return false;
  }

  void _refocus({required bool save}) {
    if (!mounted) return;
    final ayah = _ayahAtReadingLine();
    if (ayah != _focused) setState(() => _focused = ayah);
    if (save) widget.store.lastRead = (surah: surah.number, ayah: ayah);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final basmalah = widget.library.surah(1)?.ayat.first.arabic;
    final store = widget.store;

    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: ListView.builder(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    padding.top + 96,
                    24,
                    padding.bottom + 48,
                  ),
                  itemCount: surah.ayat.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _SurahOpening(
                        surah: surah,
                        basmalah: surah.headedByBasmalah ? basmalah : null,
                      );
                    }
                    final ayah = surah.ayat[index - 1];
                    final ref = (surah: surah.number, ayah: ayah.number);
                    return _AyahBlock(
                      key: _keys[index - 1],
                      ref: ref,
                      arabic: ayah.number == 1 && surah.headedByBasmalah
                          ? withoutBasmalah(ayah.arabic, basmalah ?? '')
                          : ayah.arabic,
                      translation: ayah.translation,
                      focused: _focused == ayah.number,
                      bookmarked: store.isBookmarked(ref),
                      onBookmark: () => store.toggleBookmark(ref),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: padding.top + 8,
              left: 16,
              right: 16,
              child: _ReaderBar(surah: surah),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahOpening extends StatelessWidget {
  const _SurahOpening({required this.surah, required this.basmalah});

  final Surah surah;
  final String? basmalah;

  @override
  Widget build(BuildContext context) {
    final title = TextStyler()
        .style(AppText.title.mix())
        .color(AppColors.inkPrimary());
    final meaning = TextStyler()
        .style(AppText.translation.mix())
        .color(AppColors.inkSecondary());
    final overline = TextStyler()
        .style(AppText.overline.mix())
        .color(AppColors.inkSecondary());
    final arabic = TextStyler()
        .style(AppText.ayah.mix())
        .fontSize(24)
        .height(1.8)
        .color(AppColors.inkAyah())
        .textAlign(TextAlign.center)
        .textDirection(TextDirection.rtl);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          title(surah.name),
          meaning(surah.meaning),
          const SizedBox(height: 6),
          overline(
            '${surah.makki ? 'MAKKIYAH' : 'MADANIYAH'} · '
            '${surah.ayat.length} AYAT',
          ),
          if (basmalah case final text?) ...[
            const SizedBox(height: 24),
            arabic(text),
          ],
        ],
      ),
    );
  }
}

class _AyahBlock extends StatelessWidget {
  const _AyahBlock({
    super.key,
    required this.ref,
    required this.arabic,
    required this.translation,
    required this.focused,
    required this.bookmarked,
    required this.onBookmark,
  });

  final AyahRef ref;
  final String arabic;
  final String translation;
  final bool focused;
  final bool bookmarked;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final meaning = TextStyler()
        .style(AppText.body.mix())
        .height(1.55)
        .color(AppColors.inkSecondary());
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
                    TextSpan(text: '${attachWaqfMarks(arabic)}\u00A0'),
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
              const SizedBox(height: 10),
              meaning(translation),
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
  const _ReaderBar({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final label = TextStyler()
        .style(AppText.label.mix())
        .color(AppColors.inkPrimary());
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());

    return GlassSurface(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: () => Navigator.maybePop(context),
            icon: AppIcon(
              AppGlyph.chevronLeft,
              color: AppColors.inkPrimary.resolve(context),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label('${surah.number}. ${surah.name}'),
                caption('Terjemahan Inggris sementara · Pickthall'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
