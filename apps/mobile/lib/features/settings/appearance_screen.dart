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
                          : Icons.lock_outline_rounded,
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
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          caption(label),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: children),
        ],
      ),
    );
  }
}
