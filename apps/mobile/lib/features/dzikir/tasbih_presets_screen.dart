import 'package:design_system/design_system.dart';
import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/material.dart';

import 'dzikir_services.dart';
import 'dzikir_session_controller.dart';
import 'dzikir_session_screen.dart';

/// Free tasbih: pick a goal, then a phrase.
class TasbihPresetsScreen extends StatefulWidget {
  const TasbihPresetsScreen({
    super.key,
    required this.collection,
    required this.services,
  });

  final DzikirCollection collection;
  final DzikirServices services;

  @override
  State<TasbihPresetsScreen> createState() => _TasbihPresetsScreenState();
}

/// A goal option. "Bawaan" keeps each phrase's own target from the content.
typedef _Goal = ({String label, int? Function(DzikirEntry) targetFor});

final List<_Goal> _goals = [
  (label: 'Bawaan', targetFor: (entry) => entry.target),
  (label: '33', targetFor: (_) => 33),
  (label: '99', targetFor: (_) => 99),
  (label: '100', targetFor: (_) => 100),
  (label: '∞', targetFor: (_) => null),
];

class _TasbihPresetsScreenState extends State<TasbihPresetsScreen> {
  _Goal _goal = _goals.first;

  void _start(DzikirEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DzikirSessionScreen(
          controller: DzikirSessionController.free(
            entry.withTarget(_goal.targetFor(entry)),
            widget.services,
          ),
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
    final entries = widget.collection.entries;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                tooltip: 'Kembali',
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: AlignmentDirectional.centerStart,
                ),
                onPressed: () => Navigator.maybePop(context),
                icon: AppIcon(
                  AppGlyph.chevronLeft,
                  color: AppColors.inkPrimary.resolve(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            title(widget.collection.title),
            const SizedBox(height: 28),
            overline('TARGET'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final goal in _goals)
                  AppChip(
                    label: goal.label,
                    selected: goal == _goal,
                    onPress: () => setState(() => _goal = goal),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            for (final (i, entry) in entries.indexed)
              _PresetRow(
                entry: entry,
                target: _goal.targetFor(entry),
                first: i == 0,
                onPress: () => _start(entry),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.entry,
    required this.target,
    required this.first,
    required this.onPress,
  });

  final DzikirEntry entry;
  final int? target;
  final bool first;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final arabic = TextStyler()
        .style(AppText.ayah.mix())
        .fontSize(22)
        .height(1.6)
        .color(AppColors.inkAyah())
        .textDirection(TextDirection.rtl);
    final latin = TextStyler()
        .style(AppText.label.mix())
        .fontWeight(FontWeight.w400)
        .color(AppColors.inkSecondary());
    final goal = TextStyler()
        .style(AppText.label.mix())
        .color(AppColors.accent());

    final hairline = BorderSide(color: AppColors.border.resolve(context));

    return BoxStyler().pressable(
      onPress: onPress,
      semanticsLabel: entry.text.latin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: first ? hairline : BorderSide.none,
            bottom: hairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              goal(target == null ? '∞' : '$target×'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    arabic(entry.text.arabic),
                    const SizedBox(height: 4),
                    latin(entry.text.latin),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
