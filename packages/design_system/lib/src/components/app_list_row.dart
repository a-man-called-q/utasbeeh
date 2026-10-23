import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../tokens/color_tokens.dart';
import '../tokens/text_tokens.dart';
import 'app_icon.dart';

/// A plain list row: serif title, one caption line, a trailing mark and a
/// chevron, separated by hairlines instead of sitting in a card.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    required this.onPress,
    this.overline,
    this.subtitle,
    this.trailing,
    this.highlighted = false,
    this.first = false,
  });

  /// Small accent label above the title, e.g. "SEKARANG". Pass it
  /// upper-cased.
  final String? overline;
  final String title;
  final String? subtitle;

  /// Mark before the chevron: a count, a status word, a short Arabic phrase.
  final Widget? trailing;

  /// Draws the caption in the accent, e.g. for a session in progress.
  final bool highlighted;

  /// The first row of a list also draws a hairline above itself.
  final bool first;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final kicker = TextStyler()
        .style(AppText.overline.mix())
        .color(AppColors.accent());
    final heading = TextStyler()
        .style(AppText.title.mix())
        .fontSize(21)
        .height(1.2)
        .color(AppColors.inkPrimary());
    final caption = TextStyler()
        .style(AppText.label.mix())
        .fontWeight(FontWeight.w400)
        .color(highlighted ? AppColors.accent() : AppColors.inkSecondary());
    final hairline = BorderSide(color: AppColors.border.resolve(context));

    return BoxStyler().pressable(
      onPress: onPress,
      semanticsLabel: title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: first ? hairline : BorderSide.none,
            bottom: hairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overline case final overline?) ...[
                      kicker(overline),
                      const SizedBox(height: 6),
                    ],
                    heading(title),
                    if (subtitle case final subtitle?) ...[
                      const SizedBox(height: 4),
                      caption(subtitle),
                    ],
                  ],
                ),
              ),
              if (trailing case final trailing?) ...[
                const SizedBox(width: 16),
                trailing,
              ],
              const SizedBox(width: 8),
              AppIcon(
                AppGlyph.chevronRight,
                size: 18,
                color: AppColors.inkMuted.resolve(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
