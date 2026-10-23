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
    final collections = services.library.collections;

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
            title('Dzikir'),
            const SizedBox(height: 16),
            DzikirTodayStatus(services: services),
            const SizedBox(height: 32),
            for (final (i, collection) in collections.indexed)
              DzikirCollectionRow(
                collection: collection,
                status: DzikirStatus.of(collection, services),
                highlighted: collection == suggested,
                first: i == 0,
                onPress: () => _open(collection),
              ),
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
    this.first = false,
  });

  final DzikirCollection collection;
  final DzikirStatus status;
  final bool highlighted;
  final bool first;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final word = TextStyler()
        .style(AppText.label.mix())
        .color(AppColors.accent());
    final mark = TextStyler()
        .style(AppText.title.mix())
        .fontSize(19)
        .color(AppColors.inkSecondary());

    final idle = status.kind == DzikirStatusKind.idle;

    // "Now" goes above the title, so the caption keeps to one line.
    return AppListRow(
      overline: highlighted ? 'SEKARANG' : null,
      title: collection.title,
      subtitle: idle && highlighted
          ? collection.subtitle
          : status.describe(collection),
      highlighted: status.kind == DzikirStatusKind.inProgress,
      first: first,
      onPress: onPress,
      trailing: switch (status.kind) {
        DzikirStatusKind.done => word('✓'),
        _ when collection.kind == DzikirCollectionKind.presets => mark('∞'),
        _ => mark('${collection.entries.length}'),
      },
    );
  }
}

/// "◐ Pagi, sebagian   ○ Petang, belum" for the windowed collections.
class DzikirTodayStatus extends StatelessWidget {
  const DzikirTodayStatus({super.key, required this.services});

  final DzikirServices services;

  @override
  Widget build(BuildContext context) {
    final label = TextStyler()
        .style(AppText.label.mix())
        .fontWeight(FontWeight.w400)
        .color(AppColors.inkSecondary());
    final accent = AppColors.accent.resolve(context);
    final idle = AppColors.inkMuted.resolve(context);

    Widget dot(DzikirStatusKind kind) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: kind == DzikirStatusKind.idle ? idle : accent,
        ),
        gradient: switch (kind) {
          DzikirStatusKind.done => LinearGradient(colors: [accent, accent]),
          DzikirStatusKind.inProgress => LinearGradient(
            colors: [accent, accent, accent.withValues(alpha: 0)],
            stops: const [0, 0.5, 0.5],
          ),
          DzikirStatusKind.idle => null,
        },
      ),
    );

    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        for (final collection in services.library.collections)
          if (collection.window != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                dot(DzikirStatus.of(collection, services).kind),
                const SizedBox(width: 8),
                label(
                  '${_name(collection)}, '
                  '${DzikirStatus.of(collection, services).word}',
                ),
              ],
            ),
      ],
    );
  }

  /// "Dzikir pagi" → "Pagi".
  static String _name(DzikirCollection collection) {
    final name = collection.title.replaceFirst('Dzikir ', '');
    return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
  }
}
