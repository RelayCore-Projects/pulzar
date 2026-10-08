import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/chart_data.dart';

/// A grafikon egy pontja: átlag, és ha több mérésből készült, a legkisebb / legnagyobb érték.
class ChartPoint {
  const ChartPoint(this.time, this.value, {this.min, this.max});

  final DateTime time;
  final double value;
  final int? min;
  final int? max;

  bool get hasRange => min != null && max != null && min != max;
}

/// Egy adatsor (pl. szisztolé) a saját színével és opcionális referenciavonalával.
class ChartSeries {
  ChartSeries({
    required this.label,
    required this.color,
    required List<ChartPoint> points,
    this.reference,
  }) : points = [...points]..sort((a, b) => a.time.compareTo(b.time));

  final String label;
  final Color color;
  final List<ChartPoint> points;
  final int? reference;
}

/// FR-08: több vonal egy ábrán, valós időtengellyel; a pontoknál min–max vonal;
/// FR-10: soronként szaggatott referenciavonal. Saját rajzolás (ADR-010, ADR-011).
class BpChart extends StatelessWidget {
  const BpChart({
    super.key,
    required this.series,
    required this.start,
    required this.end,
    required this.xLabels,
    this.height = 280,
  });

  final List<ChartSeries> series;
  final DateTime start;
  final DateTime end;
  final List<AxisLabel> xLabels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: BpChartPainter(
          series: series,
          start: start,
          end: end,
          xLabels: xLabels,
          gridColor: scheme.outlineVariant,
          textColor: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class BpChartPainter extends CustomPainter {
  BpChartPainter({
    required this.series,
    required this.start,
    required this.end,
    required this.xLabels,
    required this.gridColor,
    required this.textColor,
  });

  final List<ChartSeries> series;
  final DateTime start;
  final DateTime end;
  final List<AxisLabel> xLabels;
  final Color gridColor;
  final Color textColor;

  static const _left = 36.0;
  static const _right = 30.0;
  static const _top = 10.0;
  static const _bottom = 24.0;

  /// A függőleges tengely határai: minden érték, tartomány és referencia körül, 10-esre kerekítve.
  (int, int) get yRange {
    final values = <num>[
      for (final s in series) ...[
        for (final p in s.points) ...[
          p.value,
          if (p.min != null) p.min!,
          if (p.max != null) p.max!,
        ],
        if (s.reference != null) s.reference!,
      ],
    ];
    if (values.isEmpty) return (60, 160);
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final min = ((lo - 5) / 10).floor() * 10;
    final max = ((hi + 5) / 10).ceil() * 10;
    return (min, max == min ? min + 10 : max);
  }

  void _text(Canvas canvas, String s, Offset at,
      {TextAlign align = TextAlign.left, Color? color, double? minX, double? maxX}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s, style: TextStyle(color: color ?? textColor, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    if (minX != null && dx < minX) dx = minX;
    if (maxX != null && dx + tp.width > maxX) dx = maxX - tp.width;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot =
        Rect.fromLTRB(_left, _top, size.width - _right, size.height - _bottom);
    if (plot.width <= 0 || plot.height <= 0) return;
    final (yMin, yMax) = yRange;
    final span = end.difference(start).inMilliseconds.toDouble();

    double x(DateTime t) =>
        plot.left +
        plot.width *
            (span <= 0 ? 0.5 : t.difference(start).inMilliseconds / span);
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

    // időtengely feliratai
    for (final l in xLabels) {
      _text(canvas, l.text, Offset(x(l.time), plot.bottom + 12),
          align: TextAlign.center, minX: 0, maxX: size.width);
    }

    for (final s in series) {
      // referenciavonal (szaggatott, a sor színével)
      final ref = s.reference;
      if (ref != null && ref >= yMin && ref <= yMax) {
        final paint = Paint()
          ..color = s.color.withValues(alpha: 0.7)
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
        _text(canvas, '$ref', Offset(plot.right + 4, y(ref)), color: s.color);
      }

      if (s.points.isEmpty) continue;

      // napi (heti, havi) legkisebb–legnagyobb érték: vékony függőleges vonal
      final range = Paint()
        ..color = s.color.withValues(alpha: 0.45)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (final p in s.points.where((p) => p.hasRange)) {
        final px = x(p.time);
        canvas.drawLine(Offset(px, y(p.min!)), Offset(px, y(p.max!)), range);
      }

      // átlagok összekötve
      final line = Paint()
        ..color = s.color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final path = Path()
        ..moveTo(x(s.points.first.time), y(s.points.first.value));
      for (final p in s.points.skip(1)) {
        path.lineTo(x(p.time), y(p.value));
      }
      canvas.drawPath(path, line);
      final dot = Paint()..color = s.color;
      for (final p in s.points) {
        canvas.drawCircle(Offset(x(p.time), y(p.value)), 3.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(BpChartPainter old) =>
      old.start != start ||
      old.end != end ||
      old.gridColor != gridColor ||
      old.xLabels.length != xLabels.length ||
      !_sameSeries(old.series, series);

  static bool _sameSeries(List<ChartSeries> a, List<ChartSeries> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final pa = a[i].points;
      final pb = b[i].points;
      if (a[i].color != b[i].color ||
          a[i].reference != b[i].reference ||
          pa.length != pb.length) {
        return false;
      }
      for (var k = 0; k < pa.length; k++) {
        if (pa[k].time != pb[k].time ||
            pa[k].value != pb[k].value ||
            pa[k].min != pb[k].min ||
            pa[k].max != pb[k].max) {
          return false;
        }
      }
    }
    return true;
  }
}
