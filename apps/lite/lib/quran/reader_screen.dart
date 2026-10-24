import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:quran_core/quran_core.dart';

import '../settings/settings_store.dart';
import 'bookmark_store.dart';

/// One surah, ayah by ayah, each with a bookmark. Opens at [startAyah] when
/// given, with that ayah marked so the eye lands on it.
class ReaderScreen extends StatelessWidget {
  const ReaderScreen({
    super.key,
    required this.library,
    required this.store,
    required this.settings,
    required this.surah,
    this.startAyah,
  });

  final QuranLibrary library;
  final BookmarkStore store;

  /// The Arabic size.
  final LiteSettings settings;
  final Surah surah;
  final int? startAyah;

  /// Where the first visible item sits below the top: under the floating
  /// bar.
  static const _top = 96.0;

  static const _centerKey = ValueKey('reader-center');

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final basmalah = library.surah(1)?.ayat.first.arabic;
    // Item 0 is the surah opening, item n is ayah n.
    final count = surah.ayat.length + 1;
    final scale = settings.arabicSize.scale;
    final start = (startAyah ?? 0).clamp(0, surah.ayat.length);

    Widget item(int index) {
      if (index == 0) {
        return _SurahOpening(
          surah: surah,
          basmalah: surah.headedByBasmalah ? basmalah : null,
          arabicScale: scale,
        );
      }
      final ayah = surah.ayat[index - 1];
      final ref = (surah: surah.number, ayah: ayah.number);
      return _AyahBlock(
        ref: ref,
        arabic: ayah.number == 1 && surah.headedByBasmalah
            ? withoutBasmalah(ayah.arabic, basmalah ?? '')
            : ayah.arabic,
        translation: ayah.translation,
        arabicScale: scale,
        opened: ayah.number == startAyah,
        bookmarked: store.isBookmarked(ref),
        onBookmark: () => store.toggle(ref),
      );
    }

    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([store, settings]),
        builder: (context, _) => Stack(
          children: [
            // The start item is the scroll view's center, so it opens exactly
            // under the bar without measuring anything above it; earlier
            // items grow upward from it, lazily like the rest.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => CustomScrollView(
                  center: _centerKey,
                  anchor: ((padding.top + _top) / constraints.maxHeight).clamp(
                    0,
                    1,
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList.builder(
                        itemCount: start,
                        itemBuilder: (context, i) => item(start - 1 - i),
                      ),
                    ),
                    SliverPadding(
                      key: _centerKey,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        padding.bottom + 48,
                      ),
                      sliver: SliverList.builder(
                        itemCount: count - start,
                        itemBuilder: (context, i) => item(start + i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: padding.top + 8,
              left: 16,
              right: 16,
              child: _ReaderBar(
                surah: surah,
                bookmarks: store.bookmarks
                    .where((ref) => ref.surah == surah.number)
                    .length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahOpening extends StatelessWidget {
  const _SurahOpening({
    required this.surah,
    required this.basmalah,
    required this.arabicScale,
  });

  final Surah surah;
  final String? basmalah;
  final double arabicScale;

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
        .fontSize(24 * arabicScale)
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
    required this.ref,
    required this.arabic,
    required this.translation,
    required this.arabicScale,
    required this.opened,
    required this.bookmarked,
    required this.onBookmark,
  });

  final AyahRef ref;
  final String arabic;
  final String translation;
  final double arabicScale;

  /// The ayah the reader was opened at.
  final bool opened;
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
        .color(opened ? AppColors.accent() : AppColors.inkMuted());
    final accent = AppColors.accent.resolve(context);
    final hairline = BorderSide(color: AppColors.border.resolve(context));

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: hairline,
          // A thin accent rule at the start edge marks where reading opened.
          left: opened ? BorderSide(color: accent, width: 2) : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 20, bottom: 4, left: opened ? 14 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  // No-break space keeps the marker with its ayah.
                  TextSpan(text: '${attachWaqfMarks(arabic)} '),
                  TextSpan(
                    text: ayahMarker(ref.ayah),
                    style: TextStyle(color: accent),
                  ),
                ],
              ),
              style: _scaled(
                AppText.ayah.resolve(context),
                arabicScale,
              ).copyWith(color: AppColors.inkAyah.resolve(context)),
              textAlign: TextAlign.start,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            meaning(translation),
            Row(
              children: [
                address(formatAyahRef(ref)),
                const Spacer(),
                IconButton(
                  key: ValueKey('bookmark-toggle-${formatAyahRef(ref)}'),
                  tooltip: bookmarked ? 'Hapus penanda' : 'Tandai ayat',
                  onPressed: onBookmark,
                  icon: AppIcon(
                    bookmarked ? AppGlyph.bookmarkFilled : AppGlyph.bookmark,
                    size: 22,
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
    );
  }
}

class _ReaderBar extends StatelessWidget {
  const _ReaderBar({required this.surah, required this.bookmarks});

  final Surah surah;

  /// Bookmarks in this surah.
  final int bookmarks;

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
                caption(
                  bookmarks == 0
                      ? 'Ketuk penanda untuk menyimpan ayat'
                      : '$bookmarks ayat ditandai di surah ini',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _scaled(TextStyle style, double scale) =>
    style.copyWith(fontSize: (style.fontSize ?? 14) * scale);
