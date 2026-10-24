import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:quran_core/quran_core.dart';

import '../settings/settings_store.dart';
import 'bookmark_store.dart';
import 'reader_screen.dart';
import 'surah_picker_screen.dart';

/// The Qur'an tab: bookmarked ayat first and foremost, newest on top. Each
/// opens the surah at that ayah; swipe one away to remove it. Surahs are
/// one step away, behind the search row.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({
    super.key,
    required this.library,
    required this.store,
    required this.settings,
  });

  final QuranLibrary library;
  final BookmarkStore store;
  final LiteSettings settings;

  void _openPicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahPickerScreen(
          library: library,
          store: store,
          settings: settings,
        ),
      ),
    );
  }

  void _open(BuildContext context, Surah surah, int ayah) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          library: library,
          store: store,
          settings: settings,
          surah: surah,
          startAyah: ayah,
        ),
      ),
    );
  }

  void _remove(BuildContext context, AyahRef ref) {
    final index = store.remove(ref);
    final padding = MediaQuery.paddingOf(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Penanda ${formatAyahRef(ref)} dihapus'),
          behavior: SnackBarBehavior.floating,
          // Clear of the floating tab bar, which the bottom inset includes.
          margin: EdgeInsets.fromLTRB(16, 0, 16, padding.bottom + 8),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => store.insert(ref, index),
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
    final empty = TextStyler()
        .style(AppText.body.mix())
        .height(1.55)
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
            final bookmarks = [
              for (final ref in store.bookmarks)
                if (_resolve(ref) case final found?) (ref, found.$1, found.$2),
            ];

            return ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                28,
                24,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                title('Penanda'),
                const SizedBox(height: 20),
                _SearchRow(onPress: () => _openPicker(context)),
                const SizedBox(height: 32),
                if (bookmarks.isEmpty)
                  empty(
                    'Belum ada ayat yang ditandai. Buka surah, lalu ketuk '
                    'ikon penanda di samping ayat yang ingin disimpan.',
                  )
                else ...[
                  overline('${bookmarks.length} AYAT DITANDAI'),
                  const SizedBox(height: 12),
                  for (final (i, (ref, surah, ayah)) in bookmarks.indexed)
                    Dismissible(
                      key: ValueKey('bookmark-${formatAyahRef(ref)}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _remove(context, ref),
                      background: _RemoveBackground(),
                      child: AppListRow(
                        first: i == 0,
                        title: '${surah.name} ${formatAyahRef(ref)}',
                        subtitle: _snippet(ayah.translation),
                        trailing: _marker(ayah.number),
                        onPress: () => _open(context, surah, ayah.number),
                      ),
                    ),
                ],
                const SizedBox(height: 40),
                credit(
                  'Teks Arab: Tanzil Project (tanzil.net), CC BY 3.0, '
                  'tanpa perubahan. Terjemahan sementara: Marmaduke '
                  'Pickthall (1930), domain publik.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// A stored bookmark's surah and ayah, or null if it points nowhere.
  (Surah, Ayah)? _resolve(AyahRef ref) {
    final surah = library.surah(ref.surah);
    if (surah == null || ref.ayah < 1 || ref.ayah > surah.ayat.length) {
      return null;
    }
    return (surah, surah.ayat[ref.ayah - 1]);
  }

  static Widget _marker(int ayah) => TextStyler()
      .style(AppText.ayah.mix())
      .fontSize(20)
      .height(1.4)
      .color(AppColors.accent())
      .textDirection(TextDirection.rtl)(ayahMarker(ayah));

  static String _snippet(String text) =>
      text.length <= 64 ? text : '${text.substring(0, 64).trimRight()}…';
}

/// Looks like a search field; opens the surah picker, where typing happens.
class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.onPress});

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final hint = TextStyler()
        .style(AppText.label.mix())
        .fontWeight(FontWeight.w400)
        .color(AppColors.inkMuted());
    final box = BoxStyler()
        .borderRadius(.all(AppRadius.pill()))
        .border(.all(.color(AppColors.border()).width(1)));

    return Semantics(
      button: true,
      label: 'Cari surah atau ayat',
      excludeSemantics: true,
      child: box.pressable(
        onPress: onPress,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                AppIcon(
                  AppGlyph.book,
                  size: 20,
                  color: AppColors.inkMuted.resolve(context),
                ),
                const SizedBox(width: 12),
                Expanded(child: hint('Cari surah, atau ketik 2:255')),
                AppIcon(
                  AppGlyph.chevronRight,
                  size: 20,
                  color: AppColors.inkMuted.resolve(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoveBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = TextStyler()
        .style(AppText.label.mix())
        .color(AppColors.accent());
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: label('Hapus'),
      ),
    );
  }
}
