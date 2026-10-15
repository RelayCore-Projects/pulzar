import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/app.dart';
import 'package:pulzar/data/in_memory_measurement_repository.dart';
import 'package:pulzar/domain/report.dart';
import 'package:pulzar/domain/settings.dart';
import 'package:pulzar/models/measurement.dart';
import 'package:pulzar/state/measurement_store.dart';
import 'package:pulzar/state/settings_store.dart';
import 'package:pulzar/widgets/bp_chart.dart';

import 'helpers/factory.dart';
import 'helpers/fake_file_access.dart';

/// Rögzített „ma”: 2026. október 8., csütörtök.
final _today = DateTime(2026, 10, 8, 18);

DateTime _daysAgo(int days, int hour) =>
    DateTime(_today.year, _today.month, _today.day - days, hour);

List<Measurement> _sample() => [
      measurement('t1', _daysAgo(0, 1), systolic: 140, diastolic: 90, pulse: 80),
      measurement('t2', _daysAgo(1, 7), systolic: 130, diastolic: 80, pulse: 60),
      measurement('t3', _daysAgo(2, 7), systolic: 125, diastolic: 82, pulse: null),
      measurement('old', _daysAgo(20, 7), systolic: 130, diastolic: 84, pulse: 70),
    ];

class _Harness {
  late SettingsStore settings;
  late MeasurementStore store;
  final files = FakeFileAccess();
  final reports = <Report>[];

  Future<Uint8List> render(Report r) async {
    reports.add(r);
    return Uint8List.fromList('%PDF-fake'.codeUnits);
  }
}

Future<_Harness> _pump(
  WidgetTester tester, {
  List<Measurement>? initial,
  AppSettings settings = const AppSettings(),
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final h = _Harness()..settings = SettingsStore.inMemory(settings);
  h.store = MeasurementStore(InMemoryMeasurementRepository(initial ?? _sample()));
  await h.store.load();
  await tester.pumpWidget(PulzarApp(
    store: h.store,
    settings: h.settings,
    fileAccess: h.files,
    clock: () => _today,
    renderPdf: h.render,
  ));
  await tester.pumpAndSettle();
  return h;
}

TextStyle? _cellStyle(WidgetTester tester, String rowId, String text) => tester
    .widget<Text>(find.descendant(
        of: find.byKey(Key('table-row-$rowId')), matching: find.text(text)))
    .style;

BpChartPainter _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.descendant(
        of: find.byKey(const Key('chart-bp')), matching: find.byType(CustomPaint)))
    .painter! as BpChartPainter;

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('settings-button')));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('FR-15: name on PDF is saved, trimmed and can be cleared',
      (tester) async {
    final h = await _pump(tester);
    await _openSettings(tester);
    expect(find.textContaining('Not set'), findsOneWidget);

    await tester.tap(find.byKey(const Key('name-tile')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name-field')), '  Kovács  Ödön ');
    await tester.tap(find.byKey(const Key('name-save')));
    await tester.pumpAndSettle();
    expect(h.settings.value.reportName, 'Kovács Ödön');
    expect(find.text('Kovács Ödön'), findsOneWidget);

    await tester.tap(find.byKey(const Key('name-tile')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name-field')), '');
    await tester.tap(find.byKey(const Key('name-save')));
    await tester.pumpAndSettle();
    expect(h.settings.value.reportName, isNull);
  });

  testWidgets('FR-10/15: changed reference values move the dashed lines',
      (tester) async {
    final h = await _pump(tester);
    // v0.5.0: a táblázatban nincs kiemelés, a referencia felett sem
    expect(_cellStyle(tester, 't1', '140')?.fontWeight, isNot(FontWeight.bold));

    await _openSettings(tester);
    await tester.tap(find.byKey(const Key('reference-tile')));
    await tester.pumpAndSettle();
    // hibás: a diasztolé nem lehet nagyobb
    await tester.enterText(find.byKey(const Key('ref-sys-field')), '120');
    await tester.enterText(find.byKey(const Key('ref-dia-field')), '125');
    await tester.tap(find.byKey(const Key('reference-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reference-error')), findsOneWidget);
    expect(h.settings.value.refSystolic, 135);

    await tester.enterText(find.byKey(const Key('ref-sys-field')), '130');
    await tester.enterText(find.byKey(const Key('ref-dia-field')), '80');
    await tester.tap(find.byKey(const Key('reference-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reference-dialog')), findsNothing);
    expect(find.text('130 / 80 mmHg'), findsOneWidget);
    expect(h.settings.value.refSystolic, 130);
    expect(h.settings.value.refDiastolic, 80);

    await _back(tester);
    await tester.tap(find.descendant(
        of: find.byKey(const Key('main-navigation')), matching: find.text('Charts')));
    await tester.pumpAndSettle();
    expect(_painter(tester).series.map((s) => s.reference), [130, 80]);
    expect(find.text('Dashed: reference 130 / 80'), findsOneWidget);
  });

  testWidgets('FR-10/15: reference off – no dashed lines',
      (tester) async {
    final h = await _pump(tester);
    await _openSettings(tester);
    await tester.tap(find.byKey(const Key('reference-switch')));
    await tester.pumpAndSettle();
    expect(h.settings.value.referenceEnabled, isFalse);
    // az értékek szerkesztése ilyenkor nem érhető el
    expect(tester.widget<ListTile>(find.byKey(const Key('reference-tile'))).enabled,
        isFalse);
    await _back(tester);

    await tester.tap(find.descendant(
        of: find.byKey(const Key('main-navigation')), matching: find.text('Charts')));
    await tester.pumpAndSettle();
    expect(_painter(tester).series.map((s) => s.reference), [null, null]);
    expect(find.byKey(const Key('chart-reference-legend')), findsNothing);
  });

  testWidgets('FR-11: export the viewed week as PDF, then open it',
      (tester) async {
    final h = await _pump(tester,
        settings: const AppSettings(reportName: 'Anna Nagy'));
    await tester.tap(find.byKey(const Key('export-button')));
    await tester.pumpAndSettle();

    // alapból az aktuális hét eleje – ma
    expect(find.text('Monday, 5 October 2026'), findsOneWidget);
    expect(find.text('Thursday, 8 October 2026'), findsOneWidget);
    expect(find.text('3 measurements'), findsOneWidget);
    expect(find.text('Anna Nagy'), findsOneWidget);

    await tester.tap(find.byKey(const Key('export-save')));
    await tester.pumpAndSettle();

    final r = h.reports.single;
    expect(r.from, DateTime(2026, 10, 5));
    expect(r.to, DateTime(2026, 10, 8));
    expect(r.items.map((m) => m.id), ['t3', 't2', 't1']);
    expect(r.includeChart && r.includeTable, isTrue);
    expect(r.settings.reportName, 'Anna Nagy');
    expect(h.files.savedName, 'pulzar-report-2026-10-05_2026-10-08.pdf');
    expect(find.byKey(const Key('export-saved')), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(h.files.viewed, ['content://fake/pulzar-report-2026-10-05_2026-10-08.pdf']);
  });

  testWidgets('FR-11: quick ranges and table / chart switches', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byKey(const Key('export-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('export-quick-30')));
    await tester.pumpAndSettle();
    expect(find.text('Wednesday, 9 September 2026'), findsOneWidget);
    expect(find.text('4 measurements'), findsOneWidget);

    // a grafikon ki – ekkor a táblázat nem kapcsolható ki (legalább egy kell)
    await tester.tap(find.byKey(const Key('export-chart')));
    await tester.pumpAndSettle();
    expect(
        tester.widget<SwitchListTile>(find.byKey(const Key('export-table'))).onChanged,
        isNull);

    await tester.tap(find.byKey(const Key('export-save')));
    await tester.pumpAndSettle();
    final r = h.reports.single;
    expect(r.from, DateTime(2026, 9, 9));
    expect(r.includeChart, isFalse);
    expect(r.includeTable, isTrue);
    expect(r.items, hasLength(4));
  });

  testWidgets('FR-11: nothing to export in an empty period', (tester) async {
    final h = await _pump(tester, initial: [
      measurement('old', _daysAgo(20, 7)),
    ]);
    await tester.tap(find.byKey(const Key('export-button')));
    await tester.pumpAndSettle();
    expect(find.text('0 measurements'), findsOneWidget);
    expect(
        tester.widget<FilledButton>(find.byKey(const Key('export-save'))).onPressed,
        isNull);

    await tester.tap(find.byKey(const Key('export-quick-all')));
    await tester.pumpAndSettle();
    expect(find.text('1 measurement'), findsOneWidget);
    await tester.tap(find.byKey(const Key('export-save')));
    await tester.pumpAndSettle();
    expect(h.reports.single.from, DateTime(2026, 9, 18));
  });
}
