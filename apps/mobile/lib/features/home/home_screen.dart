import 'package:design_system/design_system.dart';
import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/material.dart';
import 'package:quran_core/quran_core.dart';

import '../dzikir/dzikir_list_screen.dart';
import '../dzikir/dzikir_services.dart';
import '../dzikir/dzikir_status.dart';
import '../quran/quran_store.dart';

/// "Today": the dzikir that fits the hour, the Qur'an, free tasbih.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.services,
    required this.quranLibrary,
    required this.quranStore,
    required this.onOpenQuran,
  });

  final DzikirServices services;
  final QuranLibrary quranLibrary;
  final QuranStore quranStore;
  final VoidCallback onOpenQuran;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DzikirServices get services => widget.services;

  Future<void> _open(DzikirCollection collection) async {
    await openDzikirCollection(context, collection, services);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = services.clock();
    final library = services.library;
    final suggested = library.suggestedAt(now);
    // Outside the pagi/petang windows, ba'da shalat is the likeliest need.
    final featured =
        suggested ??
        library.byId('bada_shalat') ??
        library.collections.firstWhere(
          (c) => c.kind == DzikirCollectionKind.sequence,
        );
    final presets = library.collections.where(
      (c) => c.kind == DzikirCollectionKind.presets,
    );

    final title = TextStyler()
        .style(AppText.title.mix())
        .color(AppColors.inkPrimary());
    final overline = TextStyler()
        .style(AppText.overline.mix())
        .color(AppColors.inkSecondary());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            28,
            24,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      overline(_dateLabel(now).toUpperCase()),
                      const SizedBox(height: 8),
                      title("Assalāmu'alaikum"),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/branding/tasbeeh-icon.png',
                    width: 48,
                    height: 48,
                    semanticLabel: 'Logo Tasbeeh',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DzikirTodayStatus(services: services),
            const SizedBox(height: 56),
            _FeaturedDzikir(
              collection: featured,
              status: DzikirStatus.of(featured, services),
              isNow: suggested != null,
              onPress: () => _open(featured),
            ),
            const SizedBox(height: 56),
            overline('LAINNYA'),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: widget.quranStore,
              builder: (context, _) {
                final last = widget.quranStore.lastRead;
                final surah = last == null
                    ? null
                    : widget.quranLibrary.surah(last.surah);
                return AppListRow(
                  title: "Al-Qur'an",
                  subtitle: last == null || surah == null
                      ? '${widget.quranLibrary.surahs.length} surah'
                      : 'Lanjutkan ${surah.name} ${last.surah}:${last.ayah}',
                  first: true,
                  trailing: TextStyler()
                      .style(AppText.ayah.mix())
                      .fontSize(21)
                      .height(1.4)
                      .color(AppColors.inkAyah())
                      .textDirection(TextDirection.rtl)('بِسْمِ ٱللَّهِ'),
                  onPress: widget.onOpenQuran,
                );
              },
            ),
            for (final collection in presets)
              AppListRow(
                title: collection.title,
                subtitle: DzikirStatus.of(
                  collection,
                  services,
                ).describe(collection),
                trailing: TextStyler()
                    .style(AppText.title.mix())
                    .fontSize(24)
                    .color(AppColors.inkSecondary())('∞'),
                onPress: () => _open(collection),
              ),
          ],
        ),
      ),
    );
  }

  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String _dateLabel(DateTime d) =>
      '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';
}

/// The dzikir to do now: a heading rather than a card, so it leads the page
/// on type and space alone. The whole block opens the collection.
class _FeaturedDzikir extends StatelessWidget {
  const _FeaturedDzikir({
    required this.collection,
    required this.status,
    required this.isNow,
    required this.onPress,
  });

  final DzikirCollection collection;
  final DzikirStatus status;
  final bool isNow;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final kicker = TextStyler()
        .style(AppText.overline.mix())
        .color(AppColors.accent());
    final title = TextStyler()
        .style(AppText.display.mix())
        .color(AppColors.inkPrimary());
    final meta = TextStyler()
        .style(AppText.body.mix())
        .color(AppColors.inkSecondary());
    final count = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkSecondary());
    final action = TextStyler()
        .style(AppText.label.mix())
        .fontSize(15)
        .color(AppColors.surfacePage());
    final button = BoxStyler()
        .borderRadius(.all(AppRadius.pill()))
        .color(AppColors.inkPrimary());
    final total = collection.entries.length;
    final isSequence = collection.kind == DzikirCollectionKind.sequence;

    return BoxStyler().pressable(
      onPress: onPress,
      semanticsLabel: collection.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          kicker(isNow ? 'SEKARANG' : 'SETELAH SHALAT'),
          const SizedBox(height: 10),
          title(collection.title),
          const SizedBox(height: 12),
          if (collection.subtitle case final subtitle?) meta(subtitle),
          if (isSequence) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Flexible(
                  child: _EntryTicks(
                    total: total,
                    done: status.kind == DzikirStatusKind.done
                        ? total
                        : status.completed,
                  ),
                ),
                const SizedBox(width: 12),
                count(switch (status.kind) {
                  DzikirStatusKind.idle => '$total bacaan',
                  DzikirStatusKind.inProgress =>
                    '${status.completed} dari $total',
                  DzikirStatusKind.done => 'Selesai hari ini',
                }),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Box(
            style: button,
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 24, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    action(switch (status.kind) {
                      DzikirStatusKind.inProgress => 'Lanjut',
                      DzikirStatusKind.done => 'Ulangi',
                      DzikirStatusKind.idle => 'Mulai',
                    }),
                    const SizedBox(width: 10),
                    AppIcon(
                      AppGlyph.arrowRight,
                      size: 18,
                      color: AppColors.surfacePage.resolve(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One hairline tick per entry, filled as entries are finished.
class _EntryTicks extends StatelessWidget {
  const _EntryTicks({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final filled = AppColors.accent.resolve(context);
    final empty = AppColors.brandSoft.resolve(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 216),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: i < done ? filled : empty,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
