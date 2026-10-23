import 'package:design_system/design_system.dart';
import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/material.dart';

import '../dzikir/dzikir_list_screen.dart';
import '../dzikir/dzikir_services.dart';
import '../dzikir/dzikir_status.dart';
import '../settings/appearance_screen.dart';

/// "Today": the dzikir that fits the hour, the Qur'an, free tasbih.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.services,
    required this.onOpenQuran,
  });

  final DzikirServices services;
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
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      caption(_dateLabel(now)),
                      title("Assalāmu'alaikum"),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tampilan',
                  icon: Icon(
                    Icons.tune_rounded,
                    color: AppColors.inkMuted.resolve(context),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FeaturedDzikirCard(
              collection: featured,
              status: DzikirStatus.of(featured, services),
              isNow: suggested != null,
              onPress: () => _open(featured),
            ),
            const SizedBox(height: 12),
            _QuranCard(onPress: widget.onOpenQuran),
            const SizedBox(height: 12),
            for (final collection in presets)
              DzikirCollectionRow(
                collection: collection,
                status: DzikirStatus.of(collection, services),
                highlighted: false,
                onPress: () => _open(collection),
              ),
            const SizedBox(height: 16),
            caption(dzikirTodaySummary(services)),
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

BoxStyler _cardStyle({bool emphasized = false}) => BoxStyler()
    .padding(.all(AppSpace.xl()))
    .borderRadius(.all(AppRadius.lg()))
    .color(AppColors.surfaceRaised())
    .border(
      .all(
        .color(
          emphasized ? AppColors.accent() : AppColors.border(),
        ).width(emphasized ? 1.5 : 1),
      ),
    );

class _FeaturedDzikirCard extends StatelessWidget {
  const _FeaturedDzikirCard({
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
        .style(AppText.caption.mix())
        .color(AppColors.accent());
    final title = TextStyler()
        .style(AppText.title.mix())
        .fontSize(22)
        .color(AppColors.inkPrimary());
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());
    final action = TextStyler()
        .style(AppText.label.mix())
        .color(AppColors.accent());
    final track = BoxStyler()
        .height(4)
        .borderRadius(.all(AppRadius.pill()))
        .color(AppColors.brandSoft());
    final fill = BoxStyler()
        .borderRadius(.all(AppRadius.pill()))
        .color(AppColors.accent());

    return _cardStyle(emphasized: true).pressable(
      onPress: onPress,
      semanticsLabel: collection.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          kicker(isNow ? 'Sekarang' : 'Setelah shalat'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: title(collection.title)),
              action(switch (status.kind) {
                DzikirStatusKind.inProgress => 'Lanjut',
                DzikirStatusKind.done => 'Ulangi',
                DzikirStatusKind.idle => 'Mulai',
              }),
            ],
          ),
          const SizedBox(height: 2),
          caption(
            status.kind == DzikirStatusKind.idle
                ? '${collection.entries.length} bacaan · ${collection.subtitle ?? ''}'
                : status.describe(collection),
          ),
          if (status.kind == DzikirStatusKind.inProgress) ...[
            const SizedBox(height: 12),
            Box(
              style: track,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: status.fraction.clamp(0, 1),
                  heightFactor: 1,
                  child: Box(style: fill),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuranCard extends StatelessWidget {
  const _QuranCard({required this.onPress});

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final kicker = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());
    final title = TextStyler()
        .style(AppText.title.mix())
        .fontSize(22)
        .color(AppColors.inkPrimary());
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());
    final arabic = TextStyler()
        .style(AppText.ayah.mix())
        .fontSize(20)
        .height(1.6)
        .color(AppColors.inkAyah())
        .textDirection(TextDirection.rtl);

    return _cardStyle().pressable(
      onPress: onPress,
      semanticsLabel: "Qur'an",
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                kicker("Qur'an"),
                const SizedBox(height: 4),
                title('Al-Fātiḥah'),
                const SizedBox(height: 2),
                caption('Pratinjau pembaca · Hal. 1'),
              ],
            ),
          ),
          arabic('بِسْمِ ٱللَّهِ'),
        ],
      ),
    );
  }
}
