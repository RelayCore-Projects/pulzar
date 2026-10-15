import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../app_info.dart';
import '../domain/chart_data.dart';
import '../domain/report.dart';
import '../domain/stats.dart';
import '../models/measurement.dart';
import '../util/format.dart';

/// FR-11: nyomtatható PDF (A4, álló) a [Report] alapján – ADR-012.
///
/// A betűtípus a DejaVu Sans Condensed (assets/fonts): a beépített PDF-betűk
/// nem ismerik pl. az ő, ű, č, š betűket, a név és a megjegyzés pedig bármilyen nyelvű lehet.
class ReportFonts {
  const ReportFonts(this.regular, this.bold);

  final ByteData regular;
  final ByteData bold;

  static const regularAsset = 'assets/fonts/DejaVuSansCondensed.ttf';
  static const boldAsset = 'assets/fonts/DejaVuSansCondensed-Bold.ttf';

  static Future<ReportFonts> load() async => ReportFonts(
        await rootBundle.load(regularAsset),
        await rootBundle.load(boldAsset),
      );
}

/// Az app ezt hívja (AppServices.renderPdf); a tesztek lecserélhetik.
Future<Uint8List> renderReportPdf(Report report) async =>
    buildReportPdf(report, await ReportFonts.load());

// Színek: ugyanaz a piros és kék, mint az app grafikonján (Material red/blue 700).
const _sysColor = PdfColor.fromInt(0xFFD32F2F);
const _diaColor = PdfColor.fromInt(0xFF1976D2);
const _grid = PdfColor.fromInt(0xFFDDDDDD);
const _muted = PdfColor.fromInt(0xFF666666);
const _band = PdfColor.fromInt(0xFFF3F3F3);

Future<Uint8List> buildReportPdf(Report r, ReportFonts fonts) {
  final base = pw.Font.ttf(fonts.regular);
  final bold = pw.Font.ttf(fonts.bold);
  final name = r.settings.reportName;
  final doc = pw.Document(
    title: 'Blood Pressure Log – ${r.rangeTitle}',
    author: name,
    creator: '${AppInfo.name} ${r.appVersion}',
    producer: '${AppInfo.name} ${r.appVersion}',
    theme: pw.ThemeData.withFont(base: base, bold: bold),
  );
  // a grafikon feliratai közvetlenül a PDF-vásznon (CustomPaint), ehhez saját betű-objektum –
  // csak ha van grafikon (fel nem használt betűtípus ne kerüljön a fájlba)
  final chartFont = r.includeChart && r.items.isNotEmpty
      ? PdfTtfFont(doc.document, fonts.regular)
      : null;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 30),
      // egy év napi 3 méréssel kb. 25 oldal – a korlát csak a végtelen ciklus ellen véd
      maxPages: 1000,
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Text(
                [
                  'Blood Pressure Log',
                  if (name != null) name,
                  r.rangeTitle,
                ].join(' · '),
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ),
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('${AppInfo.name} ${r.appVersion} – not a medical device',
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ],
        ),
      ),
      build: (ctx) => [
        _title(r),
        pw.SizedBox(height: 14),
        _summary(r),
        if (r.items.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 24),
            child: pw.Text('No measurements in this period.'),
          )
        else ...[
          if (chartFont != null) ...[
            pw.SizedBox(height: 18),
            _chart(r, chartFont),
          ],
          // a táblázat közvetlenül a lista eleme, így több oldalra is átnyúlhat
          if (r.includeTable) ...[
            pw.SizedBox(height: 18),
            ..._table(r),
          ],
        ],
      ],
    ),
  );
  return doc.save();
}

pw.Widget _title(Report r) {
  final name = r.settings.reportName;
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Blood Pressure Log',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      if (name != null) ...[
        pw.SizedBox(height: 4),
        pw.Text(name,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ],
      pw.SizedBox(height: 6),
      pw.Text(
        'Period: ${r.rangeTitle} (${r.days == 1 ? '1 day' : '${r.days} days'})',
        style: const pw.TextStyle(fontSize: 10),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        'Created: ${formatDate(r.createdAt)}',
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      ),
    ],
  );
}

/// FR-07: összesítő blokk.
pw.Widget _summary(Report r) {
  final stats = r.stats;
  final s = r.settings;
  const head = pw.TextStyle(fontSize: 8, color: _muted);
  const cell = pw.TextStyle(fontSize: 10);

  pw.Widget right(String text, pw.TextStyle style) =>
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(text, style: style));

  pw.TableRow row(String label, Stat? st, String unit) => pw.TableRow(children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(label, style: cell),
        ),
        for (final v in [st?.average.round(), st?.min, st?.max])
          right(v?.toString() ?? '–', cell),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 6, top: 2),
          child: pw.Text(unit, style: head),
        ),
      ]);

  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _grid),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 250,
          child: pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.6),
              1: pw.FlexColumnWidth(),
              2: pw.FlexColumnWidth(),
              3: pw.FlexColumnWidth(),
              4: pw.FlexColumnWidth(1.1),
            },
            children: [
              pw.TableRow(children: [
                pw.SizedBox(),
                right('avg', head),
                right('min', head),
                right('max', head),
                pw.SizedBox(),
              ]),
              row('Systolic', stats.systolic, 'mmHg'),
              row('Diastolic', stats.diastolic, 'mmHg'),
              row('Pulse', stats.pulse, 'bpm'),
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                stats.count == 1 ? '1 measurement' : '${stats.count} measurements',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              if (s.referenceEnabled)
                pw.Text('Reference: ${s.referenceText}',
                    style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// FR-08 / FR-10: szisztolé (piros) és diasztolé (kék) átlagai egy grafikonon.
pw.Widget _chart(Report r, PdfFont font) {
  final aggregates = r.aggregates;
  final bucket = r.bucket;
  final s = r.settings;
  final unit = switch (bucket) {
    Bucket.day => 'day',
    Bucket.week => 'week',
    Bucket.month => 'month',
  };
  final dot = switch (bucket) {
    Bucket.day => r.days <= 31 ? 2.6 : 2.0,
    Bucket.week => 1.9,
    Bucket.month => 2.4,
  };
  final labels = r.axisLabels;
  final start = r.from;
  final end = r.endExclusive;
  final span = end.difference(start).inMilliseconds.toDouble();

  // függőleges tartomány: minden átlag és referencia körül, 10-esre kerekítve
  final values = <num>[
    for (final a in aggregates) ...[a.systolic.average, a.diastolic.average],
    if (s.systolicReference != null) s.systolicReference!,
    if (s.diastolicReference != null) s.diastolicReference!,
  ];
  final lo = values.reduce(math.min);
  final hi = values.reduce(math.max);
  final yMin = ((lo - 5) / 10).floor() * 10;
  var yMax = ((hi + 5) / 10).ceil() * 10;
  if (yMax == yMin) yMax += 10;
  final step = (yMax - yMin) > 100 ? 20 : 10;

  void text(PdfGraphics c, String t, double x, double y,
      {double size = 7, PdfColor color = _muted, String align = 'left', double? width}) {
    final w = font.stringMetrics(t).width * size;
    var dx = switch (align) {
      'right' => x - w,
      'center' => x - w / 2,
      _ => x,
    };
    if (width != null) dx = dx.clamp(0, math.max(0, width - w)).toDouble();
    c
      ..setFillColor(color)
      ..drawString(font, size, t, dx, y);
  }

  void painter(PdfGraphics c, PdfPoint size) {
    const left = 28.0, right = 26.0, bottom = 16.0, top = 6.0;
    final plotW = size.x - left - right;
    final plotH = size.y - bottom - top;
    double x(DateTime t) =>
        left + plotW * (span <= 0 ? 0.5 : t.difference(start).inMilliseconds / span);
    double y(num v) => bottom + plotH * (v - yMin) / (yMax - yMin);

    // rács és függőleges feliratok
    c
      ..setStrokeColor(_grid)
      ..setLineWidth(0.5);
    for (var v = yMin; v <= yMax; v += step) {
      c
        ..drawLine(left, y(v), left + plotW, y(v))
        ..strokePath();
      text(c, '$v', left - 4, y(v) - 2.5, align: 'right');
    }
    // időtengely
    for (final l in labels) {
      final lx = x(l.time);
      c
        ..setStrokeColor(_grid)
        ..drawLine(lx, bottom, lx, bottom - 3)
        ..strokePath();
      text(c, l.text, lx, 4, align: 'center', width: size.x);
    }

    // referenciavonalak (szaggatott, a sor színével)
    void refLine(int? ref, PdfColor color) {
      if (ref == null || ref < yMin || ref > yMax) return;
      c
        ..setStrokeColor(color)
        ..setLineWidth(0.8)
        ..setLineDashPattern([4, 3])
        ..drawLine(left, y(ref), left + plotW, y(ref))
        ..strokePath()
        ..setLineDashPattern();
      text(c, '$ref', left + plotW + 4, y(ref) - 2.5, color: color);
    }

    refLine(s.systolicReference, _sysColor);
    refLine(s.diastolicReference, _diaColor);

    // pontok (összekötés nélkül – ADR-011)
    for (final (color, pick) in [
      (_sysColor, (Aggregate a) => a.systolic.average),
      (_diaColor, (Aggregate a) => a.diastolic.average),
    ]) {
      c.setFillColor(color);
      for (final a in aggregates) {
        c
          ..drawEllipse(x(a.center), y(pick(a)), dot, dot)
          ..fillPath();
      }
    }
  }

  pw.Widget legend(PdfColor color, String label, {bool dashed = false}) => pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          dashed
              ? pw.Container(width: 14, height: 1.2, color: color)
              : pw.Container(
                  width: 7,
                  height: 7,
                  decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
                ),
          pw.SizedBox(width: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        ],
      );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Blood pressure (mmHg) – ${unit == 'day' ? 'daily' : '${unit}ly'} average',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.CustomPaint(size: const PdfPoint(double.infinity, 210), painter: painter),
      pw.SizedBox(height: 6),
      pw.Row(children: [
        legend(_sysColor, 'Systolic'),
        pw.SizedBox(width: 14),
        legend(_diaColor, 'Diastolic'),
        if (s.referenceEnabled) ...[
          pw.SizedBox(width: 14),
          legend(_muted, 'Dashed: reference ${s.referenceText}', dashed: true),
        ],
      ]),
      pw.SizedBox(height: 3),
      pw.Text('Each point is the average of one $unit. '
          'The exact values are in the table.',
          style: const pw.TextStyle(fontSize: 8, color: _muted)),
    ],
  );
}

/// FR-11: minden mérés dátummal (2026.10.15 (Thursday)) és időponttal, napok szerint sávozva.
/// A referencia fölötti értékek nincsenek kiemelve (v0.5.0).
/// A fejléc minden oldalon megismétlődik.
List<pw.Widget> _table(Report r) {
  const cell = pw.TextStyle(fontSize: 9);
  final head = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);

  pw.Widget c(String t, {pw.TextStyle? style, bool alignRight = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: alignRight
            ? pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(t, style: style ?? cell))
            : pw.Text(t, style: style ?? cell),
      );

  final rows = <pw.TableRow>[
    pw.TableRow(
      repeat: true,
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _muted, width: 0.8)),
      ),
      children: [
        c('Date', style: head),
        c('Time', style: head),
        c('SYS', style: head, alignRight: true),
        c('DIA', style: head, alignRight: true),
        c('Pulse', style: head, alignRight: true),
        c('Note', style: head),
      ],
    ),
  ];

  DateTime? day;
  var shaded = true;
  for (final Measurement m in r.items) {
    final newDay = day == null || !isSameDay(day, m.measuredAt);
    if (newDay) {
      day = m.measuredAt;
      shaded = !shaded;
    }
    rows.add(pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.top,
      decoration: pw.BoxDecoration(
        color: shaded ? _band : null,
        border: newDay
            ? const pw.Border(top: pw.BorderSide(color: _grid, width: 0.5))
            : null,
      ),
      children: [
        c(newDay ? formatReportDate(m.measuredAt) : ''),
        c(formatTime(m.measuredAt)),
        c('${m.systolic}', alignRight: true),
        c('${m.diastolic}', alignRight: true),
        c(m.pulse?.toString() ?? '–', alignRight: true),
        c(m.note ?? ''),
      ],
    ));
  }

  return [
    pw.Text('Measurements',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 6),
    pw.Table(
        columnWidths: const {
          // 2026.10.15 (Wednesday) – a leghosszabb nap neve is kiférjen
          0: pw.FixedColumnWidth(106),
          1: pw.FixedColumnWidth(36),
          2: pw.FixedColumnWidth(34),
          3: pw.FixedColumnWidth(34),
          4: pw.FixedColumnWidth(38),
          5: pw.FlexColumnWidth(),
        },
        children: rows,
      ),
  ];
}
