import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../features/dzikir/dzikir_list_screen.dart';
import '../features/dzikir/dzikir_services.dart';
import '../features/home/home_screen.dart';
import '../features/quran/quran_preview_screen.dart';
import '../features/quran/quran_store.dart';
import '../features/settings/settings_screen.dart';

typedef _Tab = ({String id, String label, AppGlyph icon});

const List<_Tab> _tabs = [
  (id: 'beranda', label: 'Beranda', icon: AppGlyph.home),
  (id: 'dzikir', label: 'Dzikir', icon: AppGlyph.tasbih),
  (id: 'quran', label: "Qur'an", icon: AppGlyph.book),
  (id: 'pengaturan', label: 'Pengaturan', icon: AppGlyph.sliders),
];

/// The four tabs under one floating glass tab bar. Tab content scrolls
/// behind the bar so the glass has something to bend.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.services, required this.quran});

  final DzikirServices services;
  final QuranStore quran;

  /// Height the bar takes above the bottom safe area, including its gap.
  static const barExtent = 80.0;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Rebuilding the shell also rebuilds the kept-alive tabs, so a tab shows
  // fresh progress after work done in another tab.
  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Tabs see the bar as part of the bottom inset: their lists end above
    // it but still scroll underneath.
    final tabMedia = media.copyWith(
      padding: media.padding.copyWith(
        bottom: media.padding.bottom + HomeShell.barExtent,
      ),
    );

    return BackdropGroup(
      child: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: tabMedia,
              child: IndexedStack(
                index: _index,
                children: [
                  HomeScreen(
                    services: widget.services,
                    onOpenQuran: () => _select(2),
                  ),
                  DzikirListScreen(services: widget.services),
                  QuranPreviewScreen(store: widget.quran),
                  SettingsScreen(settings: widget.services.settings),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: media.padding.bottom + 8,
            // Outside any Scaffold, so give the labels a Material to inherit
            // text styles from (otherwise Flutter's debug underline shows).
            child: Material(
              type: MaterialType.transparency,
              child: Center(
                child: _GlassTabBar(index: _index, onSelect: _select),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 32,
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, tab) in _tabs.indexed)
            _TabButton(
              key: ValueKey('tab-${tab.id}'),
              tab: tab,
              selected: i == index,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkPrimary.resolve(context);
    final color = selected ? ink : AppColors.inkSecondary.resolve(context);
    final label = AppText.caption
        .resolve(context)
        .copyWith(color: color, fontSize: 11, fontWeight: FontWeight.w500);

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? ink.withValues(alpha: 0.07) : null,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(tab.icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(tab.label, style: label),
            ],
          ),
        ),
      ),
    );
  }
}
