import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../tokens/color_tokens.dart';
import '../tokens/layout_tokens.dart';
import '../tokens/text_tokens.dart';
import 'app_icon.dart';

/// Pill-shaped choice used for themes, modes and counter targets: a hairline
/// outline, filled with ink when selected.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.onPress,
    this.selected = false,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback onPress;
  final bool selected;

  /// Small icon after the label, e.g. a lock on premium themes.
  final AppGlyph? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final box = BoxStyler()
        .padding(.horizontal(AppSpace.lg()))
        .padding(.vertical(AppSpace.sm()))
        .borderRadius(.all(AppRadius.pill()))
        .color(selected ? AppColors.inkPrimary() : const Color(0x00000000))
        .border(
          .all(
            .color(
              selected ? AppColors.inkPrimary() : AppColors.border(),
            ).width(1),
          ),
        );
    final text = TextStyler()
        .style(AppText.label.mix())
        .color(selected ? AppColors.surfacePage() : AppColors.inkPrimary());
    final iconColor = (selected ? AppColors.surfacePage : AppColors.inkMuted)
        .resolve(context);

    return Semantics(
      selected: selected,
      child: box.pressable(
        onPress: onPress,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            text(label),
            if (trailingIcon case final icon?) ...[
              const SizedBox(width: 4),
              AppIcon(icon, size: 14, color: iconColor),
            ],
          ],
        ),
      ),
    );
  }
}
