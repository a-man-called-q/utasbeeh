import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'quran_library.dart';
import 'quran_reader_screen.dart';
import 'quran_store.dart';

/// The Qur'an tab: where reading stopped, bookmarked ayat, every surah, and
/// where the text and translation come from.
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key, required this.library, required this.store});

  final QuranLibrary library;
  final QuranStore store;

  void _open(BuildContext context, Surah surah, [int? ayah]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(
          library: library,
          store: store,
          surah: surah,
          startAyah: ayah,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = TextStyler()
        .style(AppText.title.mix())
        .color(AppColors.inkPrimary());
    final overline = TextStyler()
        .style(AppText.overline.mix())
        .color(AppColors.inkSecondary());
    final credit = TextStyler()
        .style(AppText.caption.mix())
        .height(1.6)
        .color(AppColors.inkMuted());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final last = store.lastRead;
            final lastSurah = last == null ? null : library.surah(last.surah);
            final bookmarks = [
              for (final surah in library.surahs)
                for (final ayah in surah.ayat)
                  if (store.isBookmarked((
                    surah: surah.number,
                    ayah: ayah.number,
                  )))
                    (surah, ayah),
            ];

            return ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                28,
                24,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                title("Al-Qur'an"),
                if (last != null && lastSurah != null) ...[
                  const SizedBox(height: 32),
                  overline('LANJUTKAN MEMBACA'),
                  const SizedBox(height: 12),
                  AppListRow(
                    first: true,
                    title: lastSurah.name,
                    subtitle: 'Ayat ${last.ayah} dari ${lastSurah.ayat.length}',
                    highlighted: true,
                    trailing: _arabicName(lastSurah.arabicName),
                    onPress: () => _open(context, lastSurah, last.ayah),
                  ),
                ],
                if (bookmarks.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  overline('DITANDAI'),
                  const SizedBox(height: 12),
                  for (final (i, (surah, ayah)) in bookmarks.indexed)
                    AppListRow(
                      first: i == 0,
                      title: '${surah.name} ${surah.number}:${ayah.number}',
                      subtitle: _snippet(ayah.translation),
                      onPress: () => _open(context, surah, ayah.number),
                    ),
                ],
                const SizedBox(height: 32),
                overline('SURAH'),
                const SizedBox(height: 12),
                for (final (i, surah) in library.surahs.indexed)
                  AppListRow(
                    first: i == 0,
                    title: '${surah.number}. ${surah.name}',
                    subtitle: '${surah.meaning} · ${surah.ayat.length} ayat',
                    trailing: _arabicName(surah.arabicName),
                    onPress: () => _open(context, surah),
                  ),
                const SizedBox(height: 32),
                credit(
                  'Teks Arab: Tanzil Project (tanzil.net), CC BY 3.0, '
                  'tanpa perubahan. Terjemahan sementara: Marmaduke '
                  'Pickthall (1930), domain publik. Terjemahan Kemenag '
                  'menyusul.',
                ),
              ],
            );
          },
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

  static String _snippet(String text) =>
      text.length <= 64 ? text : '${text.substring(0, 64).trimRight()}…';
}
