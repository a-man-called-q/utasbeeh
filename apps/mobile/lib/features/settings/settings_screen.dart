import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../dzikir/dzikir_services.dart';

/// The Pengaturan tab: theme, light/dark, dzikir session and glass.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final DzikirSettings settings;

  @override
  Widget build(BuildContext context) {
    final scope = AppThemeScope.of(context);
    final controller = scope.controller;
    final title = TextStyler()
        .style(AppText.title.mix())
        .color(AppColors.inkPrimary());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([controller, settings]),
          builder: (context, _) => ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              28,
              24,
              MediaQuery.paddingOf(context).bottom + 24,
            ),
            children: [
              title('Pengaturan'),
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
                label: 'Tampilkan saat berdzikir',
                children: [
                  for (final (layers, label) in const [
                    (DzikirTextLayers.arabic, 'Arab'),
                    (DzikirTextLayers.arabicLatin, 'Arab + Latin'),
                    (DzikirTextLayers.all, 'Lengkap dengan arti'),
                  ])
                    AppChip(
                      label: label,
                      selected: settings.layers == layers,
                      onPress: () => settings.layers = layers,
                    ),
                ],
              ),
              _Section(
                label: 'Ukuran teks Arab',
                children: [
                  for (final (size, label) in const [
                    (DzikirArabicSize.small, 'Kecil'),
                    (DzikirArabicSize.medium, 'Sedang'),
                    (DzikirArabicSize.large, 'Besar'),
                  ])
                    AppChip(
                      label: label,
                      selected: settings.arabicSize == size,
                      onPress: () => settings.arabicSize = size,
                    ),
                ],
              ),
              _Section(
                label: 'Getar saat menghitung',
                children: [
                  AppChip(
                    label: 'Nyala',
                    selected: settings.vibrate,
                    onPress: () => settings.vibrate = true,
                  ),
                  AppChip(
                    label: 'Mati',
                    selected: !settings.vibrate,
                    onPress: () => settings.vibrate = false,
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
