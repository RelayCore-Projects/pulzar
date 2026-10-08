import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../util/format.dart';

class ChartPoint {
  const ChartPoint(this.time, this.value);

  final DateTime time;
  final int value;
}

/// FR-08 / FR-09: vonal + pont diagram valós időtengellyel, FR-10: szaggatott referenciavonal.
/// Saját rajzolás, külső csomag nélkül (ADR-010).
class BpChart extends StatelessWidget {
  const BpChart({
    super.key,
    required this.points,
    required this.start,
    required this.end,
    required this.color,
    this.reference,
    this.height = 220,
  });

  final List<ChartPoint> points;
  final DateTime start;
  final DateTime end;
  final Color color;
  final int? reference;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: BpChartPainter(
          points: points,
          start: start,
          end: end,
          lineColor: color,
          reference: reference,
          gridColor: scheme.outlineVariant,
          textColor: scheme.onSurfaceVariant,
          referenceColor: scheme.error,
        ),
      ),
    );
  }
}

class BpChartPainter extends CustomPainter {
  BpChartPainter({
    required List<ChartPoint> points,
    required this.start,
    required this.end,
    required this.lineColor,
    required this.reference,
    required this.gridColor,
    required this.textColor,
    required this.referenceColor,
  }) : points = [...points]..sort((a, b) => a.time.compareTo(b.time));

  final List<ChartPoint> points;
  final DateTime start;
  final DateTime end;
  final Color lineColor;
  final int? reference;
  final Color gridColor;
  final Color textColor;
  final Color referenceColor;

  static const _left = 36.0;
  static const _right = 8.0;
  static const _top = 10.0;
  static const _bottom = 24.0;

  /// A függőleges tengely határai: az adatok és a referencia körül, 10-esre kerekítve.
  (int, int) get yRange {
    final ref = reference;
    final values = [for (final p in points) p.value, if (ref != null) ref];
    if (values.isEmpty) return (60, 160);
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final min = ((lo - 5) / 10).floor() * 10;
    final max = ((hi + 5) / 10).ceil() * 10;
    return (min, max == min ? min + 10 : max);
  }

  void _text(Canvas canvas, String s, Offset at, {TextAlign align = TextAlign.left, Color? color}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: color ?? textColor, fontSize: 11)),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_left, _top, size.width - _right, size.height - _bottom);
    if (plot.width <= 0 || plot.height <= 0) return;
    final (yMin, yMax) = yRange;
    final span = end.difference(start).inMilliseconds.toDouble();

    double x(DateTime t) =>
        plot.left + plot.width * (span <= 0 ? 0.5 : t.difference(start).inMilliseconds / span);
    double y(num v) => plot.bottom - plot.height * (v - yMin) / (yMax - yMin);

    // vízszintes rácsvonalak és feliratok
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final step = (yMax - yMin) > 100 ? 20 : 10;
    for (var v = yMin; v <= yMax; v += step) {
      canvas.drawLine(Offset(plot.left, y(v)), Offset(plot.right, y(v)), grid);
      _text(canvas, '$v', Offset(plot.left - 6, y(v)), align: TextAlign.right);
    }

    // időtengely feliratai (legfeljebb 5)
    final days = (span / Duration.millisecondsPerDay).round();
    final labels = math.max(2, math.min(5, days));
    for (var i = 0; i < labels; i++) {
      final t = start.add(Duration(milliseconds: (span * i / (labels - 1)).round()));
      final at = i == labels - 1 ? end.subtract(const Duration(days: 1)) : t;
      final label = '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}';
      final align = i == 0 ? TextAlign.left : (i == labels - 1 ? TextAlign.right : TextAlign.center);
      final px = i == 0 ? plot.left : (i == labels - 1 ? plot.right : x(t));
      _text(canvas, label, Offset(px, plot.bottom + 12), align: align);
    }

    // referenciavonal (szaggatott)
    final ref = reference;
    if (ref != null && ref >= yMin && ref <= yMax) {
      final paint = Paint()
        ..color = referenceColor
        ..strokeWidth = 1.5;
      const dash = 6.0;
      const gap = 4.0;
      for (var px = plot.left; px < plot.right; px += dash + gap) {
        canvas.drawLine(
          Offset(px, y(ref)),
          Offset(math.min(px + dash, plot.right), y(ref)),
          paint,
        );
      }
      _text(canvas, '$ref', Offset(plot.right - 2, y(ref) - 8),
          align: TextAlign.right, color: referenceColor);
    }

    // adatok
    if (points.isEmpty) return;
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(x(points.first.time), y(points.first.value));
    for (final p in points.skip(1)) {
      path.lineTo(x(p.time), y(p.value));
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = lineColor;
    for (final p in points) {
      canvas.drawCircle(Offset(x(p.time), y(p.value)), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(BpChartPainter old) =>
      old.points.length != points.length ||
      old.start != start ||
      old.end != end ||
      old.reference != reference ||
      old.lineColor != lineColor ||
      !_samePoints(old.points, points);

  static bool _samePoints(List<ChartPoint> a, List<ChartPoint> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].time != b[i].time || a[i].value != b[i].value) return false;
    }
    return true;
  }

  /// Teszteléshez / akadálymentesítéshez: rövid szöveges leírás.
  String describe() => points.isEmpty
      ? 'No data'
      : '${points.length} points, ${formatDate(points.first.time)} – ${formatDate(points.last.time)}';
}
