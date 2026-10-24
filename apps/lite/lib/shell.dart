import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:quran_core/quran_core.dart';

import 'quran/bookmark_store.dart';
import 'quran/bookmarks_screen.dart';
import 'tasbih/tasbih_feedback.dart';
import 'tasbih/tasbih_screen.dart';
import 'tasbih/tasbih_store.dart';

typedef _Tab = ({String id, String label, AppGlyph icon});

const List<_Tab> _tabs = [
  (id: 'tasbih', label: 'Tasbih', icon: AppGlyph.tasbih),
  (id: 'quran', label: "Qur'an", icon: AppGlyph.bookmark),
];

/// Two tabs under one floating glass tab bar.
class LiteShell extends StatefulWidget {
  const LiteShell({
    super.key,
    required this.tasbih,
    required this.feedback,
    required this.quranLibrary,
    required this.bookmarks,
  });

  final TasbihStore tasbih;
  final TasbihFeedback feedback;
  final QuranLibrary quranLibrary;
  final BookmarkStore bookmarks;

  /// Height the bar takes above the bottom safe area, including its gap.
  static const barExtent = 80.0;

  @override
  State<LiteShell> createState() => _LiteShellState();
}

class _LiteShellState extends State<LiteShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Tabs see the bar as part of the bottom inset: their content ends
    // above it but lists still scroll underneath.
    final tabMedia = media.copyWith(
      padding: media.padding.copyWith(
        bottom: media.padding.bottom + LiteShell.barExtent,
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
                  TasbihScreen(store: widget.tasbih, feedback: widget.feedback),
                  BookmarksScreen(
                    library: widget.quranLibrary,
                    store: widget.bookmarks,
                  ),
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
                child: GlassSurface(
                  radius: 32,
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, tab) in _tabs.indexed)
                        _TabButton(
                          key: ValueKey('tab-${tab.id}'),
                          tab: tab,
                          selected: i == _index,
                          onTap: () => setState(() => _index = i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
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
          width: 88,
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
