import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/data/settings_repository.dart';
import 'package:pulzar/domain/chart_data.dart';
import 'package:pulzar/domain/report.dart';
import 'package:pulzar/domain/settings.dart';
import 'package:pulzar/export/pdf_report.dart';
import 'package:pulzar/state/settings_store.dart';
import 'package:pulzar/util/format.dart';

import 'helpers/factory.dart';

ByteData _font(String path) =>
    ByteData.sublistView(File(path).readAsBytesSync());

final _fonts = ReportFonts(
  _font(ReportFonts.regularAsset),
  _font(ReportFonts.boldAsset),
);

void main() {
  group('FR-15: settings', () {
    test('defaults: no name, reference 135/85 on', () {
      const s = AppSettings();
      expect(s.reportName, isNull);
      expect(s.systolicReference, 135);
      expect(s.diastolicReference, 85);
    });

    test('reference off: no lines', () {
      const s = AppSettings(referenceEnabled: false);
      expect(s.systolicReference, isNull);
      expect(s.diastolicReference, isNull);
    });

    test('round trip through the key–value map', () {
      const s = AppSettings(
        reportName: 'Kovács Erzsébet',
        referenceEnabled: false,
        refSystolic: 130,
        refDiastolic: 80,
      );
      expect(AppSettings.fromMap(s.toMap()), s);
    });

    test('broken stored values fall back to the defaults', () {
      final s = AppSettings.fromMap({
        'reference_systolic': 'abc',
        'reference_diastolic': '999',
        'report_name': '   ',
      });
      expect(s, const AppSettings());
      // a diasztolé nem lehet ≥ szisztolé
      expect(
        AppSettings.fromMap(
            {'reference_systolic': '120', 'reference_diastolic': '125'}),
        const AppSettings(),
      );
    });

    test('name is trimmed and limited', () {
      expect(AppSettings.normalizeName('  Anna   Nagy '), 'Anna Nagy');
      expect(AppSettings.normalizeName(''), isNull);
      expect(AppSettings.normalizeName('x' * 100), hasLength(AppSettings.nameMaxLength));
    });

    test('reference validation', () {
      expect(AppSettings.validateReference(130, 80), isNull);
      expect(AppSettings.validateReference(null, 80), isNotNull);
      expect(AppSettings.validateReference(250, 80), isNotNull);
      expect(AppSettings.validateReference(130, 40), isNotNull);
      expect(AppSettings.validateReference(110, 110), contains('lower'));
    });

    test('the store saves and reloads', () async {
      final repo = InMemorySettingsRepository();
      final store = SettingsStore(repo);
      await store.load();
      expect(store.value, const AppSettings());
      await store.update(const AppSettings(reportName: 'Anna', refSystolic: 140));
      final again = SettingsStore(repo);
      await again.load();
      expect(again.value.reportName, 'Anna');
      expect(again.value.refSystolic, 140);
    });
  });

  group('FR-11: report data', () {
    final created = DateTime(2026, 10, 15, 9);
    Report report(DateTime from, DateTime to, {int perDay = 3, int days = 400}) =>
        Report(
          from: from,
          to: to,
          measurements: [
            for (var d = 0; d < days; d++)
              for (var i = 0; i < perDay; i++)
                measurement('m$d-$i', DateTime(2026, 10, 15 - d, 7 + i * 6),
                    systolic: 120 + (d + i) % 25, diastolic: 75 + d % 15),
          ],
          settings: const AppSettings(),
          createdAt: created,
          appVersion: 'test',
        );

    test('only the chosen days, oldest first, both ends included', () {
      final r = report(DateTime(2026, 10, 1), DateTime(2026, 10, 3, 23, 59));
      expect(r.days, 3);
      expect(r.items, hasLength(9));
      expect(r.items.first.measuredAt, DateTime(2026, 10, 1, 7));
      expect(r.items.last.measuredAt, DateTime(2026, 10, 3, 19));
      expect(r.fileName, 'pulzar-report-2026-10-01_2026-10-03.pdf');
      expect(r.rangeTitle, '1 – 3 October 2026');
    });

    test('the table date reads 2026.10.15 (Thursday)', () {
      expect(formatReportDate(DateTime(2026, 10, 15, 7, 30)), '2026.10.15 (Thursday)');
      expect(formatReportDate(DateTime(2026, 1, 7)), '2026.01.07 (Wednesday)');
    });

    test('swapped dates are corrected', () {
      final r = report(DateTime(2026, 10, 3), DateTime(2026, 10, 1));
      expect(r.from, DateTime(2026, 10, 1));
      expect(r.to, DateTime(2026, 10, 3));
    });

    test('one day', () {
      final r = report(DateTime(2026, 10, 2), DateTime(2026, 10, 2));
      expect(r.days, 1);
      expect(r.rangeTitle, '2 October 2026');
    });

    test('a chart point: day ≤ 2 months, week ≤ 2 years, month above', () {
      expect(reportBucket(1), Bucket.day);
      expect(reportBucket(62), Bucket.day);
      expect(reportBucket(63), Bucket.week);
      expect(reportBucket(731), Bucket.week);
      expect(reportBucket(732), Bucket.month);
    });

    test('day count ignores daylight saving time', () {
      // 2026. október 25.: óraátállítás Közép-Európában
      expect(daysBetween(DateTime(2026, 10, 20), DateTime(2026, 10, 30)), 10);
      expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    });

    test('axis labels stay readable for any range', () {
      for (final (from, to) in [
        (DateTime(2026, 10, 8), DateTime(2026, 10, 8)),
        (DateTime(2026, 10, 1), DateTime(2026, 10, 7)),
        (DateTime(2026, 7, 16), DateTime(2026, 10, 15)),
        (DateTime(2025, 10, 16), DateTime(2026, 10, 15)),
        (DateTime(2020, 1, 1), DateTime(2026, 10, 15)),
      ]) {
        final labels = rangeAxisLabels(from, to);
        expect(labels, isNotEmpty, reason: '$from – $to');
        expect(labels.length, lessThanOrEqualTo(12), reason: '$from – $to');
        final end = DateTime(to.year, to.month, to.day + 1);
        for (final l in labels) {
          expect(!l.time.isBefore(from) && l.time.isBefore(end), isTrue,
              reason: '${l.text} $from – $to');
        }
      }
    });
  });

  group('FR-11: PDF', () {
    Future<Uint8List> pdf(Report r) => buildReportPdf(r, _fonts);

    bool isPdf(Uint8List b) => String.fromCharCodes(b.take(5)) == '%PDF-';

    test('empty period still gives a valid PDF', () async {
      final bytes = await pdf(Report(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 7),
        measurements: const [],
        settings: const AppSettings(),
        createdAt: DateTime(2026, 10, 15),
        appVersion: 'test',
      ));
      expect(isPdf(bytes), isTrue);
    });

    test('name and notes with Hungarian / Slovak letters, table only', () async {
      final bytes = await pdf(Report(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 7),
        measurements: [
          measurement('a', DateTime(2026, 10, 2, 7), systolic: 150, diastolic: 95,
              note: 'Gyógyszer előtt – ő, ű, č, š, ž, ľ 😀'),
          measurement('b', DateTime(2026, 10, 2, 19), pulse: null, note: 'x' * 200),
        ],
        settings: const AppSettings(reportName: 'Kovács Ödön – Žilina'),
        createdAt: DateTime(2026, 10, 15),
        appVersion: 'test',
        includeChart: false,
      ));
      expect(isPdf(bytes), isTrue);
    });

    test('a year with 3 measurements a day spans many pages', () async {
      final items = [
        for (var d = 0; d < 365; d++)
          for (var i = 0; i < 3; i++)
            measurement('m$d-$i', DateTime(2026, 10, 15 - d, 7 + i * 6),
                systolic: 115 + (d * 7 + i) % 40, diastolic: 70 + d % 25,
                note: d % 10 == 0 ? 'After coffee' : null),
      ];
      final r = Report(
        from: DateTime(2025, 10, 16),
        to: DateTime(2026, 10, 15),
        measurements: items,
        settings: const AppSettings(refSystolic: 130, refDiastolic: 80),
        createdAt: DateTime(2026, 10, 15),
        appVersion: 'test',
      );
      expect(r.bucket, Bucket.week);
      final bytes = await pdf(r);
      expect(isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(20000));
    });

    test('chart only, reference off, several years', () async {
      final bytes = await pdf(Report(
        from: DateTime(2023, 1, 1),
        to: DateTime(2026, 10, 15),
        measurements: [
          for (var d = 0; d < 1300; d += 3)
            measurement('m$d', DateTime(2026, 10, 15 - d, 8),
                systolic: 120 + d % 30, diastolic: 80 + d % 10),
        ],
        settings: const AppSettings(referenceEnabled: false),
        createdAt: DateTime(2026, 10, 15),
        appVersion: 'test',
        includeTable: false,
      ));
      expect(isPdf(bytes), isTrue);
    });
  });
}
