import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'sample_surahs.dart';

/// Temporary screen to check tokens, themes and glass on a device.
/// Reader text scrolls under two floating glass bars, the way the real
/// reader will.
class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: BackdropGroup(
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  padding.top + 88,
                  24,
                  padding.bottom + 220,
                ),
                children: [
                  for (final surah in sampleSurahs)
                    _SurahSection(
                      name: surah.name,
                      meaning: surah.meaning,
                      ayat: surah.ayat,
                    ),
                ],
              ),
            ),
            Positioned(
              top: padding.top + 8,
              left: 16,
              right: 16,
              child: const _ReaderBar(),
            ),
            Positioned(
              bottom: padding.bottom + 12,
              left: 16,
              right: 16,
              child: const _ThemePanel(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahSection extends StatelessWidget {
  const _SurahSection({
    required this.name,
    required this.meaning,
    required this.ayat,
  });

  final String name;
  final String meaning;
  final List<String> ayat;

  @override
  Widget build(BuildContext context) {
    final title = TextStyler()
        .style(AppText.title.mix())
        .color(AppColors.inkPrimary());
    final subtitle = TextStyler()
        .style(AppText.translation.mix())
        .color(AppColors.inkSecondary());

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpace.xxl.resolve(context)),
      child: Column(
        children: [
          title(name),
          subtitle(meaning),
          SizedBox(height: AppSpace.lg.resolve(context)),
          // Markers are text, not WidgetSpans: Flutter can hand placeholder
          // boxes back in visual order in RTL lines, which swaps the ayah
          // numbers when two markers share a line.
          Text.rich(
            TextSpan(
              children: [
                for (final (index, ayah) in ayat.indexed) ...[
                  // No-break space keeps the marker on its ayah's line.
                  TextSpan(text: '$ayah '),
                  TextSpan(
                    text: ayahMarker(index + 1),
                    style: TextStyle(color: AppColors.accent.resolve(context)),
                  ),
                  const TextSpan(text: ' '),
                ],
              ],
            ),
            style: AppText.ayah
                .resolve(context)
                .copyWith(color: AppColors.inkAyah.resolve(context)),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

/// End-of-ayah marker in ornate parentheses with Arabic-Indic digits,
/// e.g. ﴿١٢﴾. Written in logical (RTL) order.
String ayahMarker(int number) {
  final digits = number
      .toString()
      .split('')
      .map((d) => _arabicDigits[int.parse(d)])
      .join();
  return '﴿$digits﴾';
}

class _ReaderBar extends StatelessWidget {
  const _ReaderBar();

  @override
  Widget build(BuildContext context) {
    final label = TextStyler()
        .style(AppText.label.mix())
        .color(AppColors.inkPrimary());
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());
    final muted = AppColors.inkMuted.resolve(context);

    return GlassSurface(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.chevron_left_rounded, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label('Pratinjau desain'), caption('Hal. 1 · Juz 1')],
            ),
          ),
          Icon(Icons.bookmark_outline_rounded, color: muted),
        ],
      ),
    );
  }
}

class _ThemePanel extends StatelessWidget {
  const _ThemePanel();

  @override
  Widget build(BuildContext context) {
    final scope = AppThemeScope.of(context);
    final controller = scope.controller;
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());

    return GlassSurface(
      radius: 28,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          caption('Tema'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final theme in controller.registry.themes)
                _Chip(
                  label: theme.name,
                  selected: scope.theme.id == theme.id,
                  locked: !controller.isUnlocked(theme),
                  onPress: () => controller.isUnlocked(theme)
                      ? controller.select(theme.id)
                      : controller.preview(theme.id),
                ),
              if (controller.isPreviewing)
                _Chip(
                  label: 'Selesai pratinjau',
                  onPress: controller.endPreview,
                ),
            ],
          ),
          const SizedBox(height: 12),
          caption('Mode'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final (mode, label) in const [
                (AppThemeMode.system, 'Sistem'),
                (AppThemeMode.light, 'Terang'),
                (AppThemeMode.dark, 'Gelap'),
              ])
                _Chip(
                  label: label,
                  selected: controller.mode == mode,
                  onPress: () => controller.mode = mode,
                ),
            ],
          ),
          const SizedBox(height: 12),
          caption('Kaca'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final mode in GlassMode.values)
                _Chip(
                  label: mode.name,
                  selected: controller.glassMode == mode,
                  onPress: () => controller.glassMode = mode,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onPress,
    this.selected = false,
    this.locked = false,
  });

  final String label;
  final VoidCallback onPress;
  final bool selected;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final box = BoxStyler()
        .padding(.horizontal(AppSpace.md()))
        .padding(.vertical(AppSpace.sm()))
        .borderRadius(.all(AppRadius.pill()))
        .color(selected ? AppColors.accent() : AppColors.brandSoft());
    final text = TextStyler()
        .style(AppText.label.mix())
        .color(selected ? AppColors.onAccent() : AppColors.inkPrimary());
    final iconColor = (selected ? AppColors.onAccent : AppColors.inkMuted)
        .resolve(context);

    return box.pressable(
      onPress: onPress,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          text(label),
          if (locked) ...[
            const SizedBox(width: 4),
            Icon(Icons.lock_outline_rounded, size: 14, color: iconColor),
          ],
        ],
      ),
    );
  }
}
