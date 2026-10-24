import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'settings_store.dart';

/// The Pengaturan tab: theme, light/dark, counting vibration and the
/// reader's Arabic size.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final LiteSettings settings;

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
                  // Lite has no purchases, so only free themes are offered.
                  for (final theme in controller.registry.themes)
                    if (!theme.isPremium)
                      AppChip(
                        label: theme.name,
                        selected: scope.theme.id == theme.id,
                        onPress: () => controller.select(theme.id),
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
                label: "Ukuran teks Arab Qur'an",
                children: [
                  for (final (size, label) in const [
                    (ArabicSize.small, 'Kecil'),
                    (ArabicSize.medium, 'Sedang'),
                    (ArabicSize.large, 'Besar'),
                  ])
                    AppChip(
                      label: label,
                      selected: settings.arabicSize == size,
                      onPress: () => settings.arabicSize = size,
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
