import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../settings/settings_store.dart';
import 'tasbih_feedback.dart';
import 'tasbih_store.dart';

/// Just the count: tap or swipe anywhere above the buttons to count, −1 to
/// take one back, "Ulang" to start from zero.
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({
    super.key,
    required this.store,
    required this.feedback,
    required this.settings,
  });

  final TasbihStore store;
  final TasbihFeedback feedback;

  /// Whether counting vibrates.
  final LiteSettings settings;

  /// Touches this close to the left, right or bottom edge of the counting
  /// area don't count: the system back and home gestures live there.
  static const edgeDeadZone = 24.0;

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  Offset? _panStart;

  TasbihStore get store => widget.store;

  void _count() {
    store.increment();
    if (widget.settings.vibrate) widget.feedback.onCount(store.count);
  }

  void _decrement() {
    store.decrement();
    if (widget.settings.vibrate) widget.feedback.onStep();
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mulai dari nol?'),
        content: Text('Hitungan ${store.count} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ulang'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      store.reset();
      if (widget.settings.vibrate) widget.feedback.onStep();
    }
  }

  /// Built inside the store's listener so it repaints on every count.
  Widget _countArea() {
    final count = TextStyler()
        .style(AppText.counter.mix())
        .color(AppColors.inkPrimary());
    final hint = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted())
        .textAlign(TextAlign.center);

    // The buttons sit below the counting area, not inside it, so pressing
    // them can never also count.
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        const dead = TasbihScreen.edgeDeadZone;
        bool counts(Offset p) =>
            p.dx >= dead &&
            p.dx <= size.width - dead &&
            p.dy <= size.height - dead;

        return Semantics(
          button: true,
          label: 'Tambah hitungan',
          value: '${store.count}',
          onTap: _count,
          child: GestureDetector(
            key: const ValueKey('tasbih-area'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              if (counts(details.localPosition)) _count();
            },
            onPanStart: (details) => _panStart = details.localPosition,
            onPanEnd: (_) {
              final start = _panStart;
              _panStart = null;
              if (start != null && counts(start)) _count();
            },
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: _Ring(child: count('${store.count}'))),
                  const SizedBox(height: 24),
                  hint('Ketuk atau geser di mana saja'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = TextStyler()
        .style(AppText.title.mix())
        .color(AppColors.inkPrimary());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: title('Tasbih'),
                ),
              ),
              Expanded(child: _countArea()),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  MediaQuery.paddingOf(context).bottom + 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PillButton(
                      label: '−1',
                      semanticsLabel: 'Kurangi satu hitungan',
                      onPressed: store.count > 0 ? _decrement : null,
                    ),
                    const SizedBox(width: 12),
                    _PillButton(
                      label: 'Ulang',
                      semanticsLabel: 'Ulang dari nol',
                      onPressed: store.count > 0 ? _reset : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A hairline circle around the count. Scales down on short screens rather
/// than overflowing.
class _Ring extends StatelessWidget {
  const _Ring({required this.child});

  static const _diameter = 240.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight < _diameter
            ? constraints.maxHeight
            : _diameter;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.resolve(context)),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        );
      },
    );
  }
}

/// A large, labelled pill for unsteady hands.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String label;
  final String semanticsLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final text = TextStyler()
        .style(AppText.label.mix())
        .fontSize(16)
        .color(AppColors.inkPrimary());
    final box = BoxStyler()
        .borderRadius(.all(AppRadius.pill()))
        .border(.all(.color(AppColors.border()).width(1)));

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: box.pressable(
          onPress: onPressed ?? () {},
          enabled: enabled,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96),
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(widthFactor: 1, child: text(label)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
