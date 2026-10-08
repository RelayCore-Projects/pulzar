import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/app.dart';
import 'package:pulzar/app_info.dart';
import 'package:pulzar/data/in_memory_measurement_repository.dart';
import 'package:pulzar/models/measurement.dart';
import 'package:pulzar/state/measurement_store.dart';

import 'helpers/factory.dart';

/// Rögzített „ma”: 2026. október 8., csütörtök 18:00.
final _today = DateTime(2026, 10, 8, 18);

Finder _navLabel(String label) => find.descendant(
      of: find.byKey(const Key('main-navigation')),
      matching: find.text(label),
    );

Finder _inRow(String id, Finder f) =>
    find.descendant(of: find.byKey(Key('table-row-$id')), matching: f);

Future<MeasurementStore> _pumpApp(
  WidgetTester tester, {
  List<Measurement> initial = const [],
}) async {
  final store = MeasurementStore(InMemoryMeasurementRepository(initial));
  await store.load();
  await tester.pumpWidget(PulzarApp(store: store, clock: () => _today));
  await tester.pumpAndSettle();
  return store;
}

Future<void> _fillForm(
  WidgetTester tester, {
  required String sys,
  required String dia,
  required String pulse,
}) async {
  await tester.enterText(find.byKey(const Key('field-systolic')), sys);
  await tester.enterText(find.byKey(const Key('field-diastolic')), dia);
  await tester.enterText(find.byKey(const Key('field-pulse')), pulse);
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('save-button')));
  await tester.pumpAndSettle();
}

Future<void> _openNew(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('add-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Starts on the Table with an add button; two tabs', (tester) async {
    await _pumpApp(tester);
    expect(find.byKey(const Key('table-empty')), findsOneWidget);
    expect(find.byKey(const Key('add-button')), findsOneWidget);
    expect(_navLabel('Table'), findsOneWidget);
    expect(_navLabel('Charts'), findsOneWidget);
    expect(_navLabel('Log'), findsNothing);
  });

  testWidgets('The navigation bar switches between views', (tester) async {
    await _pumpApp(tester);

    await tester.tap(_navLabel('Charts'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('charts-empty')), findsOneWidget);
    expect(find.byKey(const Key('add-button')), findsNothing);

    await tester.tap(_navLabel('Table'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('table-empty')), findsOneWidget);
  });

  testWidgets('FR-01: a new measurement appears in the table', (tester) async {
    final store = await _pumpApp(tester);

    await _openNew(tester);
    expect(find.text('New measurement'), findsOneWidget);
    await _fillForm(tester, sys: '128', dia: '82', pulse: '72');
    await tester.enterText(find.byKey(const Key('field-note')), 'left arm');
    await _tapSave(tester);

    expect(store.measurements, hasLength(1));
    final m = store.measurements.single;
    expect(m.note, 'left arm');
    expect(m.measuredAt, DateTime(2026, 10, 8, 18));
    expect(find.byKey(const Key('table-day-2026-10-08')), findsOneWidget);
    expect(_inRow(m.id, find.text('128')), findsOneWidget);
    expect(_inRow(m.id, find.text('72')), findsOneWidget);
    expect(_inRow(m.id, find.byKey(const Key('note-icon'))), findsOneWidget);
  });

  testWidgets('FR-01: pulse can be left empty (#3)', (tester) async {
    final store = await _pumpApp(tester);

    await _openNew(tester);
    expect(find.text('Pulse (optional)'), findsOneWidget);
    await _fillForm(tester, sys: '128', dia: '82', pulse: '');
    await _tapSave(tester);

    final m = store.measurements.single;
    expect(m.pulse, isNull);
    expect(_inRow(m.id, find.text('–')), findsOneWidget);
    expect(_inRow(m.id, find.byKey(const Key('note-icon'))), findsNothing);
  });

  testWidgets('FR-02: diastolic must be lower than systolic', (tester) async {
    final store = await _pumpApp(tester);

    await _openNew(tester);
    await _fillForm(tester, sys: '80', dia: '90', pulse: '70');
    await _tapSave(tester);

    expect(find.text('Must be lower than systolic'), findsOneWidget);
    expect(store.measurements, isEmpty);
  });

  testWidgets('FR-02: empty and out-of-range values are rejected',
      (tester) async {
    final store = await _pumpApp(tester);

    await _openNew(tester);
    await _fillForm(tester, sys: '400', dia: '', pulse: '70');
    await _tapSave(tester);

    expect(find.text('Must be between 50 and 300'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
    expect(store.measurements, isEmpty);
  });

  testWidgets('FR-03: the daily limit offers editing an existing one',
      (tester) async {
    final day = DateTime(2026, 10, 8);
    final store = await _pumpApp(tester, initial: [
      measurement('a', day.add(const Duration(hours: 7)), systolic: 121),
      measurement('b', day.add(const Duration(hours: 12)), systolic: 122),
      measurement('c', day.add(const Duration(hours: 17)), systolic: 123),
    ]);

    await _openNew(tester);
    await _fillForm(tester, sys: '130', dia: '85', pulse: '70');
    await _tapSave(tester);

    expect(find.byKey(const Key('daily-limit-dialog')), findsOneWidget);
    expect(store.measurements, hasLength(3));

    await tester.tap(find.byKey(const Key('limit-edit-b')));
    await tester.pumpAndSettle();
    expect(find.text('Edit measurement'), findsOneWidget);
    final systolicField =
        tester.widget<TextFormField>(find.byKey(const Key('field-systolic')));
    expect(systolicField.controller!.text, '122');
  });

  testWidgets('FR-04: tap a row to edit, then delete', (tester) async {
    final store = await _pumpApp(tester, initial: [
      measurement('m1', DateTime(2026, 10, 7, 7, 30), note: 'a long note'),
    ]);

    await tester.tap(find.byKey(const Key('table-row-m1')));
    await tester.pumpAndSettle();
    expect(find.text('Edit measurement'), findsOneWidget);
    // a teljes megjegyzés az űrlapon látszik
    final noteField =
        tester.widget<TextFormField>(find.byKey(const Key('field-note')));
    expect(noteField.controller!.text, 'a long note');

    await tester.enterText(find.byKey(const Key('field-pulse')), '88');
    await _tapSave(tester);
    expect(store.measurements.single.pulse, 88);
    expect(_inRow('m1', find.text('88')), findsOneWidget);

    await tester.tap(find.byKey(const Key('table-row-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();
    expect(store.measurements, isEmpty);
    expect(find.byKey(const Key('table-empty')), findsOneWidget);
  });

  testWidgets('FR-04: pulse can be removed when editing (#3)', (tester) async {
    final store = await _pumpApp(tester, initial: [
      measurement('p1', DateTime(2026, 10, 7, 8), pulse: 66),
    ]);

    await tester.tap(find.byKey(const Key('table-row-p1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-pulse')), '');
    await _tapSave(tester);

    expect(store.measurements.single.pulse, isNull);
  });

  testWidgets('About shows the medical disclaimer (FR-16)', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-tile')));
    await tester.pumpAndSettle();

    expect(find.text(AppInfo.disclaimer), findsOneWidget);
    expect(find.textContaining('MIT'), findsOneWidget);
  });

  test('Default reference values are 135/85 mmHg (FR-10)', () {
    expect(AppInfo.defaultRefSystolic, 135);
    expect(AppInfo.defaultRefDiastolic, 85);
  });
}
