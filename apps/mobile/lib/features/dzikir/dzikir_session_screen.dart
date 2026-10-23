import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/material.dart';

import 'dzikir_session_controller.dart';

/// Runs one session. Each entry renders in its own mode: counted entries
/// turn the whole screen into the counter, read entries scroll with a done
/// button. Owns and disposes [controller].
class DzikirSessionScreen extends StatefulWidget {
  const DzikirSessionScreen({super.key, required this.controller});

  final DzikirSessionController controller;

  @override
  State<DzikirSessionScreen> createState() => _DzikirSessionScreenState();
}

class _DzikirSessionScreenState extends State<DzikirSessionScreen> {
  DzikirSessionController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.services.keepAwake(true);
  }

  @override
  void dispose() {
    controller.services.keepAwake(false);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = AppThemeScope.of(context).controller;
    // Sessions stay dark by default (setting "Gelap saat berdzikir"); the
    // Builder makes the Scaffold resolve its colors inside the override.
    final screen = Builder(
      builder: (context) => Scaffold(
        backgroundColor: AppColors.surfacePage.resolve(context),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final session = controller.session;
              final sequenceDone =
                  session.isComplete &&
                  session.collection.kind == DzikirCollectionKind.sequence;
              return Column(
                children: [
                  _SessionHeader(session: session),
                  Expanded(
                    child: sequenceDone
                        ? _CompletionView(collection: session.collection)
                        : switch (session.currentEntry.mode) {
                            DzikirMode.count => _CountView(
                              controller: controller,
                            ),
                            DzikirMode.read => _ReadView(
                              key: ValueKey(session.entryIndex),
                              controller: controller,
                            ),
                          },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) => themeController.darkSessions
          ? AppBrightnessOverride(brightness: Brightness.dark, child: child!)
          : child!,
      child: screen,
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.session});

  final DzikirSession session;

  @override
  Widget build(BuildContext context) {
    final collection = session.collection;
    final isSequence = collection.kind == DzikirCollectionKind.sequence;
    final total = collection.entries.length;
    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted());
    final label = TextStyler()
        .style(AppText.label.mix())
        .color(AppColors.inkSecondary());
    final target = session.currentEntry.target;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.maybePop(context),
                icon: AppIcon(
                  AppGlyph.close,
                  color: AppColors.inkMuted.resolve(context),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    caption(collection.title),
                    label(
                      isSequence
                          ? '${math.min(session.completedEntries + 1, total)} / $total'
                          : target == null
                          ? 'Tanpa target'
                          : 'Target $target',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          if (isSequence)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _ProgressBar(value: session.completedEntries / total),
            ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final track = BoxStyler()
        .height(3)
        .borderRadius(.all(AppRadius.pill()))
        .color(AppColors.brandSoft());
    final fill = BoxStyler()
        .borderRadius(.all(AppRadius.pill()))
        .color(AppColors.accent());
    return Box(
      style: track,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          heightFactor: 1,
          child: Box(style: fill),
        ),
      ),
    );
  }
}

/// Short text: tap or swipe anywhere counts, except near the screen edges
/// where the system back and home gestures live.
class _CountView extends StatefulWidget {
  const _CountView({required this.controller});

  final DzikirSessionController controller;

  static const edgeDeadZone = 24.0;

  @override
  State<_CountView> createState() => _CountViewState();
}

class _CountViewState extends State<_CountView> {
  Offset? _panStart;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final session = controller.session;
    final entry = session.currentEntry;
    final target = entry.target;
    final reachedOpenTarget = session.isComplete;

    final arabic = TextStyler()
        .style(AppText.ayah.mix())
        .fontSize(30)
        .color(AppColors.inkAyah())
        .textAlign(TextAlign.center)
        .textDirection(TextDirection.rtl);
    final latin = TextStyler()
        .style(AppText.body.mix())
        .color(AppColors.inkSecondary())
        .textAlign(TextAlign.center);
    final meaning = TextStyler()
        .style(AppText.translation.mix())
        .color(AppColors.inkMuted())
        .textAlign(TextAlign.center);
    final count = TextStyler()
        .style(AppText.counter.mix())
        .color(AppColors.inkPrimary());
    final goal = TextStyler()
        .style(AppText.label.mix())
        .fontWeight(FontWeight.w400)
        .letterSpacing(0.5)
        .color(AppColors.inkSecondary());
    final hint = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted())
        .textAlign(TextAlign.center);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        const dead = _CountView.edgeDeadZone;
        bool counts(Offset p) =>
            p.dx >= dead &&
            p.dx <= size.width - dead &&
            p.dy <= size.height - dead;

        return Semantics(
          button: true,
          label: 'Tambah hitungan',
          onTap: controller.increment,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              if (counts(details.localPosition)) controller.increment();
            },
            onPanStart: (details) => _panStart = details.localPosition,
            onPanEnd: (_) {
              final start = _panStart;
              _panStart = null;
              if (start != null && counts(start)) controller.increment();
            },
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    arabic(entry.text.arabic),
                    const SizedBox(height: 8),
                    latin(entry.text.latin),
                    const SizedBox(height: 4),
                    meaning(entry.text.translation),
                    const SizedBox(height: 36),
                    _CounterBead(
                      phrase: entry.text.arabic,
                      progress: target == null
                          ? null
                          : (session.count / target).clamp(0, 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          count('${session.count}'),
                          const SizedBox(height: 6),
                          goal(target == null ? '∞' : 'dari $target'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    hint(
                      reachedOpenTarget
                          ? 'Target tercapai · boleh lanjut menghitung'
                          : 'Ketuk atau geser di mana saja',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The glass bead holding the count, inside a hairline ring that fills
/// toward the target. Glass over a flat page reads as a plain disc, so the
/// phrase is repeated faintly behind it for the glass to bend, fading out
/// radially so it has no hard edges.
class _CounterBead extends StatelessWidget {
  const _CounterBead({
    required this.phrase,
    required this.progress,
    required this.child,
  });

  static const _diameter = 200.0;
  static const _ring = 240.0;

  final String phrase;

  /// 0–1 toward the target; null when the entry has no target.
  final double? progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final backdrop = AppText.ayah
        .resolve(context)
        .copyWith(
          fontSize: 40,
          height: 1.5,
          color: AppColors.inkAyah.resolve(context).withValues(alpha: 0.10),
        );

    return SizedBox(
      height: _ring + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const RadialGradient(
                colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                stops: [0.5, 1],
              ).createShader(bounds),
              child: ClipRect(
                // Wider than the screen so lines run off both edges like a
                // strip of beads; the mask fades them out before the clip.
                child: OverflowBox(
                  maxWidth: 640,
                  child: Text(
                    List.filled(8, phrase).join('  '),
                    style: backdrop,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 4,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ),
          ),
          SizedBox.square(
            dimension: _ring,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                track: AppColors.border.resolve(context),
                fill: AppColors.accent.resolve(context),
              ),
            ),
          ),
          GlassSurface(
            radius: _diameter / 2,
            child: SizedBox.square(dimension: _diameter, child: child),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double? progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = track,
    );
    final sweep = (progress ?? 0) * 2 * math.pi;
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}

/// Long text: scrolls freely; the glass button counts one recitation.
class _ReadView extends StatefulWidget {
  const _ReadView({super.key, required this.controller});

  final DzikirSessionController controller;

  @override
  State<_ReadView> createState() => _ReadViewState();
}

class _ReadViewState extends State<_ReadView> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _done() {
    final session = widget.controller.session;
    final entryBefore = session.entryIndex;
    widget.controller.increment();
    // Another recitation of the same text: start again from the top.
    if (session.entryIndex == entryBefore && _scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.session;
    final entry = session.currentEntry;
    final target = entry.target ?? 1;
    final isLast = session.count + 1 >= target;

    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted())
        .textAlign(TextAlign.center);
    final arabic = TextStyler()
        .style(AppText.ayah.mix())
        .color(AppColors.inkAyah())
        .textAlign(TextAlign.center)
        .textDirection(TextDirection.rtl);
    final latin = TextStyler()
        .style(AppText.body.mix())
        .color(AppColors.inkSecondary());
    final meaning = TextStyler()
        .style(AppText.translation.mix())
        .color(AppColors.inkSecondary());
    final button = TextStyler()
        .style(AppText.label.mix())
        .fontSize(15)
        .color(AppColors.accent());

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                caption(
                  target > 1
                      ? 'Dibaca $target× · bacaan ke-${session.count + 1}'
                      : 'Dibaca 1×',
                ),
                const SizedBox(height: 12),
                arabic(entry.text.arabic),
                const SizedBox(height: 16),
                latin(entry.text.latin),
                const SizedBox(height: 12),
                meaning(entry.text.translation),
                const SizedBox(height: 12),
                caption(entry.source),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Semantics(
            button: true,
            child: GestureDetector(
              onTap: _done,
              child: GlassSurface(
                radius: 28,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: button(
                    isLast
                        ? 'Selesai, lanjut'
                        : 'Selesai (${session.count + 1}/$target)',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.collection});

  final DzikirCollection collection;

  @override
  Widget build(BuildContext context) {
    final arabic = TextStyler()
        .style(AppText.ayah.mix())
        .fontSize(36)
        .color(AppColors.accent())
        .textDirection(TextDirection.rtl);
    final title = TextStyler()
        .style(AppText.title.mix())
        .color(AppColors.inkPrimary())
        .textAlign(TextAlign.center);
    final caption = TextStyler()
        .style(AppText.translation.mix())
        .color(AppColors.inkSecondary())
        .textAlign(TextAlign.center);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          arabic('الْحَمْدُ لِلَّهِ'),
          const SizedBox(height: 12),
          title('${collection.title} selesai'),
          const SizedBox(height: 4),
          caption('Semoga Allah menerimanya.'),
          const SizedBox(height: 28),
          AppChip(
            label: 'Kembali',
            selected: true,
            onPress: () => Navigator.maybePop(context),
          ),
        ],
      ),
    );
  }
}
