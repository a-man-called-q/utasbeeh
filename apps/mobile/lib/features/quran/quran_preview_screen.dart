import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'sample_surahs.dart';

/// Qur'an tab until the real reader lands: sample surahs scrolling under a
/// floating glass bar, the way the reader will look.
class QuranPreviewScreen extends StatelessWidget {
  const QuranPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                padding.top + 88,
                24,
                padding.bottom + 32,
              ),
              children: [
                for (final surah in sampleSurahs)
                  _SurahSection(
                    name: surah.name,
                    meaning: surah.meaning,
                    ayat: surah.ayat,
                  ),
              ],
            ),
          ),
          Positioned(
            top: padding.top + 8,
            left: 16,
            right: 16,
            child: const _ReaderBar(),
          ),
        ],
      ),
    );
  }
}

class _SurahSection extends StatelessWidget {
  const _SurahSection({
    required this.name,
    required this.meaning,
    required this.ayat,
  });

  final String name;
  final String meaning;
  final List<String> ayat;

  @override
  Widget build(BuildContext context) {
    final title = TextStyler()
        .style(AppText.title.mix())
        .color(AppColors.inkPrimary());
    final subtitle = TextStyler()
        .style(AppText.translation.mix())
        .color(AppColors.inkSecondary());

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpace.xxl.resolve(context)),
      child: Column(
        children: [
          title(name),
          subtitle(meaning),
          SizedBox(height: AppSpace.lg.resolve(context)),
          // Markers are text, not WidgetSpans: Flutter can hand placeholder
          // boxes back in visual order in RTL lines, which swaps the ayah
          // numbers when two markers share a line.
          Text.rich(
            TextSpan(
              children: [
                for (final (index, ayah) in ayat.indexed) ...[
                  // No-break space keeps the marker on its ayah's line.
                  TextSpan(text: '$ayah '),
                  TextSpan(
                    text: ayahMarker(index + 1),
                    style: TextStyle(color: AppColors.accent.resolve(context)),
                  ),
                  const TextSpan(text: ' '),
                ],
              ],
            ),
            style: AppText.ayah
                .resolve(context)
                .copyWith(color: AppColors.inkAyah.resolve(context)),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
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
  const _ReaderBar();

  @override
  Widget build(BuildContext context) {
    final label = TextStyler()
        .style(AppText.label.mix())
        .color(AppColors.inkPrimary());
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());
    final muted = AppColors.inkMuted.resolve(context);

    return GlassSurface(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label('Pratinjau pembaca'), caption('Hal. 1 · Juz 1')],
            ),
          ),
          Icon(Icons.bookmark_outline_rounded, color: muted),
        ],
      ),
    );
  }
}
