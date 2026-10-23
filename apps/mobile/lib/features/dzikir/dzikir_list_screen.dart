import 'package:design_system/design_system.dart';
import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/material.dart';

import 'dzikir_services.dart';
import 'dzikir_session_controller.dart';
import 'dzikir_session_screen.dart';
import 'dzikir_status.dart';
import 'tasbih_presets_screen.dart';

/// Opens [collection]: a session for sequences, the phrase picker for free
/// tasbih. Completes when the user comes back.
Future<void> openDzikirCollection(
  BuildContext context,
  DzikirCollection collection,
  DzikirServices services,
) {
  final Widget screen = switch (collection.kind) {
    DzikirCollectionKind.sequence => DzikirSessionScreen(
      controller: DzikirSessionController.forCollection(collection, services),
    ),
    DzikirCollectionKind.presets => TasbihPresetsScreen(
      collection: collection,
      services: services,
    ),
  };
  return Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

class DzikirListScreen extends StatefulWidget {
  const DzikirListScreen({super.key, required this.services});

  final DzikirServices services;

  @override
  State<DzikirListScreen> createState() => _DzikirListScreenState();
}

class _DzikirListScreenState extends State<DzikirListScreen> {
  DzikirServices get services => widget.services;

  Future<void> _open(DzikirCollection collection) async {
    await openDzikirCollection(context, collection, services);
    // Progress and completion changed while the session was open.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final suggested = services.library.suggestedAt(services.clock());
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
            title('Dzikir'),
            const SizedBox(height: 4),
            caption(dzikirTodaySummary(services)),
            const SizedBox(height: 16),
            for (final collection in services.library.collections) ...[
              DzikirCollectionRow(
                collection: collection,
                status: DzikirStatus.of(collection, services),
                highlighted: collection == suggested,
                onPress: () => _open(collection),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class DzikirCollectionRow extends StatelessWidget {
  const DzikirCollectionRow({
    super.key,
    required this.collection,
    required this.status,
    required this.highlighted,
    required this.onPress,
  });

  final DzikirCollection collection;
  final DzikirStatus status;
  final bool highlighted;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final inProgress = status.kind == DzikirStatusKind.inProgress;
    final box = BoxStyler()
        .padding(.all(AppSpace.lg()))
        .borderRadius(.all(AppRadius.md()))
        .color(AppColors.surfaceRaised())
        .border(
          .all(
            .color(
              highlighted ? AppColors.accent() : AppColors.border(),
            ).width(highlighted ? 1.5 : 1),
          ),
        );
    final title = TextStyler()
        .style(AppText.body.mix())
        .fontWeight(FontWeight.w500)
        .color(AppColors.inkPrimary());
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());
    final trailing = TextStyler()
        .style(AppText.label.mix())
        .color(
          inProgress || highlighted ? AppColors.accent() : AppColors.inkMuted(),
        );

    final trailingLabel = switch (status.kind) {
      DzikirStatusKind.inProgress => 'Lanjut',
      DzikirStatusKind.done => '✓',
      _ when collection.kind == DzikirCollectionKind.presets => '∞',
      _ => '${collection.entries.length}',
    };

    return box.pressable(
      onPress: onPress,
      semanticsLabel: collection.title,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title(collection.title),
                caption(status.describe(collection, now: highlighted)),
              ],
            ),
          ),
          trailing(trailingLabel),
        ],
      ),
    );
  }
}
