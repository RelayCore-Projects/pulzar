import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/chart_data.dart';

/// A grafikon egy pontja: egy nap (évnél egy hét) átlaga.
class ChartPoint {
  const ChartPoint(this.time, this.value);

  final DateTime time;
  final double value;
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

/// FR-08: több adatsor egy ábrán, csak pontokkal, valós időtengellyel;
/// FR-10: soronként szaggatott referenciavonal; koppintásra egy időpont kiemelése.
/// Saját rajzolás (ADR-010, ADR-011).
class BpChart extends StatelessWidget {
  const BpChart({
    super.key,
    required this.series,
    required this.start,
    required this.end,
    required this.xLabels,
    this.dotRadius = 4.5,
    this.highlight,
    this.onTapTime,
    this.height = 280,
  });

  final List<ChartSeries> series;
  final DateTime start;
  final DateTime end;
  final List<AxisLabel> xLabels;
  final double dotRadius;

  /// A kiemelt pont ideje (a sorok azonos idejű pontjait függőleges vonal köti össze).
  final DateTime? highlight;

  /// Koppintás: a koppintás helyéhez tartozó idő.
  final ValueChanged<DateTime>? onTapTime;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onTapTime == null
              ? null
              : (d) {
                  final t = BpChartPainter.timeAt(
                      d.localPosition.dx, constraints.maxWidth, start, end);
                  if (t != null) onTapTime!(t);
                },
          child: CustomPaint(
            size: Size(constraints.maxWidth, height),
            painter: BpChartPainter(
              series: series,
              start: start,
              end: end,
              xLabels: xLabels,
              dotRadius: dotRadius,
              highlight: highlight,
              gridColor: scheme.outlineVariant,
              textColor: scheme.onSurfaceVariant,
              highlightColor: scheme.onSurface,
            ),
          ),
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
    this.dotRadius = 4.5,
    this.highlight,
    this.highlightColor = Colors.black,
  });

  final List<ChartSeries> series;
  final DateTime start;
  final DateTime end;
  final List<AxisLabel> xLabels;
  final Color gridColor;
  final Color textColor;
  final double dotRadius;
  final DateTime? highlight;
  final Color highlightColor;

  static const _left = 36.0;
  static const _right = 30.0;

  /// Vízszintes képpont → idő (a rajzterület bal és jobb szélén kívül null).
  static DateTime? timeAt(double dx, double width, DateTime start, DateTime end) {
    final plotWidth = width - _left - _right;
    if (plotWidth <= 0) return null;
    final f = (dx - _left) / plotWidth;
    if (f < -0.02 || f > 1.02) return null;
    final span = end.difference(start).inMilliseconds;
    return start.add(Duration(milliseconds: (span * f.clamp(0.0, 1.0)).round()));
  }

  /// Idő → vízszintes képpont (tesztekhez is).
  static double xFor(DateTime t, double width, DateTime start, DateTime end) {
    final plotWidth = width - _left - _right;
    final span = end.difference(start).inMilliseconds;
    return _left + plotWidth * (span <= 0 ? 0.5 : t.difference(start).inMilliseconds / span);
  }
  static const _top = 10.0;
  static const _bottom = 24.0;

  /// A függőleges tengely határai: minden érték, tartomány és referencia körül, 10-esre kerekítve.
  (int, int) get yRange {
    final values = <num>[
      for (final s in series) ...[
        for (final p in s.points) p.value,
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

    }

    // kiemelés: az azonos idejű pontokat (SYS–DIA) függőleges vonal köti össze
    final h = highlight;
    if (h != null) {
      final ys = [
        for (final s in series)
          for (final p in s.points)
            if (p.time == h) y(p.value),
      ];
      if (ys.isNotEmpty) {
        final px = x(h);
        final paint = Paint()
          ..color = highlightColor.withValues(alpha: 0.6)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(px, ys.reduce(math.min)), Offset(px, ys.reduce(math.max)), paint);
      }
    }

    // csak pontok, összekötés nélkül – egy kimaradt nap ne tűnjön folytonosnak (v0.4.0)
    for (final s in series) {
      final dot = Paint()..color = s.color;
      final ring = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final p in s.points) {
        final c = Offset(x(p.time), y(p.value));
        canvas.drawCircle(c, dotRadius, dot);
        if (p.time == h) canvas.drawCircle(c, dotRadius + 3, ring);
      }
    }
  }

  @override
  bool shouldRepaint(BpChartPainter old) =>
      old.start != start ||
      old.end != end ||
      old.gridColor != gridColor ||
      old.xLabels.length != xLabels.length ||
      old.highlight != highlight ||
      old.dotRadius != dotRadius ||
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
        if (pa[k].time != pb[k].time || pa[k].value != pb[k].value) {
          return false;
        }
      }
    }
    return true;
  }
}
