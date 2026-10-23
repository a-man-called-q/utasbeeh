import 'package:flutter/widgets.dart';

/// The app's line icons, drawn on a 24-unit grid with one stroke weight so
/// they read as a set (Material's filled, rounded glyphs did not).
enum AppGlyph {
  home,
  tasbih,
  book,
  bookmark,
  sliders,
  close,
  chevronLeft,
  chevronRight,
  arrowRight,
  lock,
}

/// A thin-stroke icon. Color defaults to the ambient [IconTheme], like
/// [Icon], so it drops into [IconButton] unchanged.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.glyph, {
    super.key,
    this.size = 22,
    this.color,
    this.semanticLabel,
  });

  final AppGlyph glyph;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color =
        this.color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    final icon = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GlyphPainter(glyph, color)),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: icon)
        : Semantics(label: semanticLabel, child: icon);
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color);

  final AppGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final path = Path();

    void line(List<Offset> points) {
      path.moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    }

    void circle(double x, double y, double r) =>
        path.addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

    switch (glyph) {
      case AppGlyph.home:
        line(const [
          Offset(4, 10.5),
          Offset(12, 4),
          Offset(20, 10.5),
          Offset(20, 20),
          Offset(15, 20),
          Offset(15, 14.5),
          Offset(9, 14.5),
          Offset(9, 20),
          Offset(4, 20),
        ]);
        path.close();
      case AppGlyph.tasbih:
        circle(12, 13, 7);
        circle(12, 4, 1.6);
      case AppGlyph.book:
        path
          ..moveTo(3, 5.5)
          ..cubicTo(6, 4.5, 9, 4.5, 12, 6.5)
          ..cubicTo(15, 4.5, 18, 4.5, 21, 5.5)
          ..lineTo(21, 19)
          ..cubicTo(18, 18, 15, 18, 12, 20)
          ..cubicTo(9, 18, 6, 18, 3, 19)
          ..close();
        line(const [Offset(12, 6.5), Offset(12, 20)]);
      case AppGlyph.bookmark:
        line(const [
          Offset(7, 4),
          Offset(17, 4),
          Offset(17, 20),
          Offset(12, 16),
          Offset(7, 20),
        ]);
        path.close();
      case AppGlyph.sliders:
        line(const [Offset(4, 7), Offset(13, 7)]);
        line(const [Offset(17, 7), Offset(20, 7)]);
        line(const [Offset(4, 17), Offset(7, 17)]);
        line(const [Offset(11, 17), Offset(20, 17)]);
        circle(15, 7, 2);
        circle(9, 17, 2);
      case AppGlyph.close:
        line(const [Offset(6, 6), Offset(18, 18)]);
        line(const [Offset(18, 6), Offset(6, 18)]);
      case AppGlyph.chevronLeft:
        line(const [Offset(15, 6), Offset(9, 12), Offset(15, 18)]);
      case AppGlyph.chevronRight:
        line(const [Offset(9, 6), Offset(15, 12), Offset(9, 18)]);
      case AppGlyph.arrowRight:
        line(const [Offset(5, 12), Offset(19, 12)]);
        line(const [Offset(13, 6), Offset(19, 12), Offset(13, 18)]);
      case AppGlyph.lock:
        path.addRRect(RRect.fromLTRBR(5, 11, 19, 20, const Radius.circular(2)));
        path
          ..moveTo(8, 11)
          ..lineTo(8, 8)
          ..arcToPoint(const Offset(16, 8), radius: const Radius.circular(4))
          ..lineTo(16, 11);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
