import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/material.dart';

import 'dzikir_services.dart';
import 'dzikir_session_controller.dart';

/// Runs one session. Each entry renders in its own mode: counted entries
/// turn the whole screen into the counter, long read entries go one
/// sentence at a time. Owns and disposes [controller].
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
                  _SessionHeader(controller: controller),
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

/// Close in the middle, previous and next entry at the far edges, so the
/// three never sit close enough to be confused. None of it counts.
class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.controller});

  final DzikirSessionController controller;

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
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
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              if (isSequence)
                _HeaderButton(
                  glyph: AppGlyph.chevronLeft,
                  tooltip: 'Bacaan sebelumnya',
                  onPressed: session.canGoBack ? controller.previous : null,
                )
              else
                const SizedBox(width: _HeaderButton.size),
              const Spacer(),
              _HeaderButton(
                glyph: AppGlyph.close,
                tooltip: 'Tutup',
                onPressed: () => Navigator.maybePop(context),
              ),
              const Spacer(),
              if (isSequence)
                _HeaderButton(
                  glyph: AppGlyph.chevronRight,
                  tooltip: 'Bacaan berikutnya',
                  onPressed: session.canGoForward ? controller.next : null,
                )
              else
                const SizedBox(width: _HeaderButton.size),
            ],
          ),
          const SizedBox(height: 4),
          caption(collection.title),
          label(
            isSequence
                ? '${session.entryIndex + 1} / $total'
                : target == null
                ? 'Tanpa target'
                : 'Target $target',
          ),
          if (isSequence)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _ProgressBar(value: session.completedEntries / total),
            ),
        ],
      ),
    );
  }
}

/// A large, plainly drawn header button; dimmed when it can't act.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.glyph,
    required this.tooltip,
    required this.onPressed,
  });

  static const size = 56.0;

  final AppGlyph glyph;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkPrimary.resolve(context);
    return SizedBox.square(
      dimension: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: AppIcon(
          glyph,
          size: 26,
          color: onPressed == null ? ink.withValues(alpha: 0.25) : ink,
        ),
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

    // The −1 button sits below the counting area, not inside it, so pressing
    // it can never also count.
    final countArea = LayoutBuilder(
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
                    _Recitation(
                      arabic: entry.text.arabic,
                      latin: entry.text.latin,
                      translation: entry.text.translation,
                      settings: controller.services.settings,
                      arabicSize: 30,
                    ),
                    const SizedBox(height: 36),
                    Flexible(
                      child: _CounterBead(
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

    return Column(
      children: [
        Expanded(child: countArea),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
          child: _PillButton(
            label: '−1',
            semanticsLabel: 'Kurangi satu hitungan',
            onPressed: session.canDecrement ? controller.decrement : null,
          ),
        ),
      ],
    );
  }
}

/// A large, labelled pill for unsteady hands: −1, previous sentence.
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

/// Arabic first and largest; Latin smaller, in italic serif and the
/// secondary ink; the meaning last, in plain sans and the faintest ink. Which lines show follows
/// [DzikirSettings.layers]; the Arabic size follows its size setting.
class _Recitation extends StatelessWidget {
  const _Recitation({
    required this.arabic,
    required this.latin,
    required this.translation,
    required this.settings,
    required this.arabicSize,
    this.label,
  });

  final String arabic;
  final String latin;
  final String? translation;
  final String? label;
  final DzikirSettings settings;

  /// Arabic font size at the medium setting.
  final double arabicSize;

  @override
  Widget build(BuildContext context) {
    final layers = settings.layers;
    final kicker = TextStyler()
        .style(AppText.overline.mix())
        .color(AppColors.accent())
        .textAlign(TextAlign.center);
    final arabicText = TextStyler()
        .style(AppText.ayah.mix())
        .fontSize(arabicSize * settings.arabicSize.scale)
        .height(1.9)
        .color(AppColors.inkAyah())
        .textAlign(TextAlign.center)
        .textDirection(TextDirection.rtl);
    final latinText = TextStyler()
        .style(AppText.translation.mix())
        .fontSize(18)
        .height(1.45)
        .fontStyle(FontStyle.italic)
        .color(AppColors.inkSecondary())
        .textAlign(TextAlign.center);
    final meaning = TextStyler()
        .style(AppText.body.mix())
        .fontSize(14)
        .height(1.55)
        .color(AppColors.inkMuted())
        .textAlign(TextAlign.center);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label case final label?) ...[
          kicker(label.toUpperCase()),
          const SizedBox(height: 12),
        ],
        arabicText(attachWaqfMarks(arabic)),
        if (layers.latin) ...[const SizedBox(height: 14), latinText(latin)],
        if (layers.translation && translation != null) ...[
          const SizedBox(height: 14),
          meaning(translation!),
        ],
      ],
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

  static const _height = _ring + 40;

  @override
  Widget build(BuildContext context) {
    // On short screens the whole bead scales down rather than overflowing.
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(1.0, constraints.maxHeight / _height);
        return SizedBox(
          height: _height * scale,
          child: OverflowBox(
            maxHeight: _height,
            minHeight: _height,
            child: Transform.scale(scale: scale, child: _bead(context)),
          ),
        );
      },
    );
  }

  Widget _bead(BuildContext context) {
    final backdrop = AppText.ayah
        .resolve(context)
        .copyWith(
          fontSize: 40,
          height: 1.5,
          color: AppColors.inkAyah.resolve(context).withValues(alpha: 0.10),
        );

    return SizedBox(
      height: _height,
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

/// Long text. With parts, one sentence at a time; otherwise a scroll.
class _ReadView extends StatelessWidget {
  const _ReadView({super.key, required this.controller});

  final DzikirSessionController controller;

  @override
  Widget build(BuildContext context) =>
      controller.session.currentEntry.text.segments.isEmpty
      ? _ScrollReadView(controller: controller)
      : _SentenceView(controller: controller);
}

/// One sentence on screen, everything else out of sight, so the eye has a
/// single place to rest. Tap anywhere for the next sentence; tapping the
/// last counts one recitation and starts the text over if more are due.
///
/// The sentence lives in the session, so it is saved with the progress and
/// survives closing the app.
class _SentenceView extends StatelessWidget {
  const _SentenceView({required this.controller});

  final DzikirSessionController controller;

  void _next() => controller.session.canGoForwardPart
      ? controller.nextPart()
      : controller.increment();

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    final entry = session.currentEntry;
    final parts = entry.text.segments;
    final index = session.part;
    final part = parts[index];
    final target = entry.target ?? 1;
    final isLast = !session.canGoForwardPart;

    final caption = TextStyler()
        .style(AppText.caption.mix())
        .color(AppColors.inkMuted())
        .textAlign(TextAlign.center);

    final stage = LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        const dead = _CountView.edgeDeadZone;
        return Semantics(
          button: true,
          label: isLast ? 'Selesai membaca' : 'Kalimat berikutnya',
          onTap: _next,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final p = details.localPosition;
              if (p.dx >= dead && p.dx <= size.width - dead) _next();
            },
            child: Center(
              child: SingleChildScrollView(
                key: ValueKey(index),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                child: _Recitation(
                  arabic: part.arabic,
                  latin: part.latin,
                  translation: part.translation,
                  label: part.label,
                  settings: controller.services.settings,
                  arabicSize: 32,
                ),
              ),
            ),
          ),
        );
      },
    );

    return Column(
      children: [
        const SizedBox(height: 12),
        caption(
          target > 1
              ? 'Dibaca $target× · bacaan ke-${session.count + 1}'
              : 'Dibaca 1×',
        ),
        const SizedBox(height: 10),
        _SentenceDots(count: parts.length, current: index),
        Expanded(child: stage),
        caption(
          isLast
              ? (session.count + 1 < target
                    ? 'Ketuk untuk selesai bacaan ke-${session.count + 1}'
                    : 'Ketuk untuk selesai')
              : 'Ketuk untuk kalimat berikutnya',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PillButton(
                label: '‹ Kalimat',
                semanticsLabel: 'Kalimat sebelumnya',
                onPressed: session.canGoBackPart
                    ? controller.previousPart
                    : null,
              ),
              const SizedBox(width: 12),
              _PillButton(
                label: '−1',
                semanticsLabel: 'Kurangi satu hitungan',
                onPressed: session.canDecrement ? controller.decrement : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Where in the text you are: done sentences filled, the rest hollow.
class _SentenceDots extends StatelessWidget {
  const _SentenceDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent.resolve(context);
    final idle = AppColors.border.resolve(context);
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i <= current ? accent : idle,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

/// Long text without parts: scrolls freely; the glass button counts one
/// recitation.
class _ScrollReadView extends StatefulWidget {
  const _ScrollReadView({required this.controller});

  final DzikirSessionController controller;

  @override
  State<_ScrollReadView> createState() => _ScrollReadViewState();
}

class _ScrollReadViewState extends State<_ScrollReadView> {
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
                _Recitation(
                  arabic: entry.text.arabic,
                  latin: entry.text.latin,
                  translation: entry.text.translation,
                  settings: widget.controller.services.settings,
                  arabicSize: 26,
                ),
                const SizedBox(height: 16),
                caption(entry.source),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Row(
            children: [
              _PillButton(
                label: '−1',
                semanticsLabel: 'Kurangi satu hitungan',
                onPressed: session.canDecrement
                    ? widget.controller.decrement
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
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
