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
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                tooltip: 'Kembali',
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.inkMuted.resolve(context),
                ),
              ),
            ),
            title(widget.collection.title),
            const SizedBox(height: 16),
            caption('Target'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final goal in _goals)
                  AppChip(
                    label: goal.label,
                    selected: goal == _goal,
                    onPress: () => setState(() => _goal = goal),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            for (final entry in widget.collection.entries) ...[
              _PresetRow(
                entry: entry,
                target: _goal.targetFor(entry),
                onPress: () => _start(entry),
              ),
              const SizedBox(height: 8),
            ],
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
    required this.onPress,
  });

  final DzikirEntry entry;
  final int? target;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final box = BoxStyler()
        .padding(.all(AppSpace.lg()))
        .borderRadius(.all(AppRadius.md()))
        .color(AppColors.surfaceRaised())
        .border(.all(.color(AppColors.border()).width(1)));
    final arabic = TextStyler()
        .style(AppText.ayah.mix())
        .fontSize(22)
        .height(1.6)
        .color(AppColors.inkAyah())
        .textDirection(TextDirection.rtl);
    final latin = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkSecondary());
    final goal = TextStyler()
        .style(AppText.label.mix())
        .color(AppColors.accent());

    return box.pressable(
      onPress: onPress,
      semanticsLabel: entry.text.latin,
      child: Row(
        children: [
          goal(target == null ? '∞' : '$target×'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [arabic(entry.text.arabic), latin(entry.text.latin)],
            ),
          ),
        ],
      ),
    );
  }
}
