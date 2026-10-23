import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Theme, light/dark, glass and dzikir-session settings.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppThemeScope.of(context);
    final controller = scope.controller;
    final title = TextStyler()
        .style(AppText.title.mix())
        .color(AppColors.inkPrimary());

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => ListView(
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
              title('Tampilan'),
              _Section(
                label: 'Tema',
                children: [
                  for (final theme in controller.registry.themes)
                    AppChip(
                      label: theme.name,
                      selected: scope.theme.id == theme.id,
                      trailingIcon: controller.isUnlocked(theme)
                          ? null
                          : AppGlyph.lock,
                      onPress: () => controller.isUnlocked(theme)
                          ? controller.select(theme.id)
                          : controller.preview(theme.id),
                    ),
                  if (controller.isPreviewing)
                    AppChip(
                      label: 'Selesai pratinjau',
                      onPress: controller.endPreview,
                    ),
                ],
              ),
              _Section(
                label: 'Mode',
                children: [
                  for (final (mode, label) in const [
                    (AppThemeMode.system, 'Sistem'),
                    (AppThemeMode.light, 'Terang'),
                    (AppThemeMode.dark, 'Gelap'),
                  ])
                    AppChip(
                      label: label,
                      selected: controller.mode == mode,
                      onPress: () => controller.mode = mode,
                    ),
                ],
              ),
              _Section(
                label: 'Saat berdzikir',
                children: [
                  AppChip(
                    label: 'Selalu gelap',
                    selected: controller.darkSessions,
                    onPress: () => controller.darkSessions = true,
                  ),
                  AppChip(
                    label: 'Ikut mode',
                    selected: !controller.darkSessions,
                    onPress: () => controller.darkSessions = false,
                  ),
                ],
              ),
              _Section(
                label: 'Kaca',
                children: [
                  for (final (mode, label) in const [
                    (GlassMode.liquid, 'Liquid'),
                    (GlassMode.frosted, 'Buram'),
                    (GlassMode.solid, 'Tanpa kaca'),
                  ])
                    AppChip(
                      label: label,
                      selected: controller.glassMode == mode,
                      onPress: () => controller.glassMode = mode,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final overline = TextStyler()
        .style(AppText.overline.mix())
        .color(AppColors.inkSecondary());
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          overline(label.toUpperCase()),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}
