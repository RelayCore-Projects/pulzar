import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/app.dart';
import 'package:pulzar/app_info.dart';
import 'package:pulzar/data/in_memory_measurement_repository.dart';
import 'package:pulzar/models/measurement.dart';
import 'package:pulzar/state/measurement_store.dart';

import 'helpers/factory.dart';

Finder _navLabel(String label) => find.descendant(
      of: find.byKey(const Key('main-navigation')),
      matching: find.text(label),
    );

Future<MeasurementStore> _pumpApp(
  WidgetTester tester, {
  List<Measurement> initial = const [],
}) async {
  final store = MeasurementStore(InMemoryMeasurementRepository(initial));
  await store.load();
  await tester.pumpWidget(PulzarApp(store: store));
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

void main() {
  testWidgets('Empty log on first start', (tester) async {
    await _pumpApp(tester);
    expect(find.byKey(const Key('log-empty')), findsOneWidget);
    expect(find.byKey(const Key('add-button')), findsOneWidget);
    expect(_navLabel('Log'), findsOneWidget);
    expect(_navLabel('Table'), findsOneWidget);
    expect(_navLabel('Charts'), findsOneWidget);
  });

  testWidgets('The navigation bar switches between views', (tester) async {
    await _pumpApp(tester);

    await tester.tap(_navLabel('Table'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('table-empty')), findsOneWidget);
    expect(find.byKey(const Key('add-button')), findsNothing);

    await tester.tap(_navLabel('Charts'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('charts-empty')), findsOneWidget);
  });

  testWidgets('FR-01 / FR-05: a new measurement appears in the log',
      (tester) async {
    final store = await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('add-button')));
    await tester.pumpAndSettle();
    expect(find.text('New measurement'), findsOneWidget);

    await _fillForm(tester, sys: '128', dia: '82', pulse: '72');
    await tester.enterText(find.byKey(const Key('field-note')), 'left arm');
    await _tapSave(tester);

    expect(store.measurements, hasLength(1));
    expect(store.measurements.single.note, 'left arm');
    expect(find.text('128 / 82 mmHg'), findsOneWidget);
    expect(find.text('72 bpm'), findsOneWidget);
    expect(find.textContaining('Today'), findsOneWidget);
  });

  testWidgets('FR-01: pulse can be left empty (#3)', (tester) async {
    final store = await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('add-button')));
    await tester.pumpAndSettle();
    expect(find.text('Pulse (optional)'), findsOneWidget);
    await _fillForm(tester, sys: '128', dia: '82', pulse: '');
    await _tapSave(tester);

    expect(store.measurements.single.pulse, isNull);
    expect(find.text('128 / 82 mmHg'), findsOneWidget);
    expect(find.textContaining('bpm'), findsNothing);
  });

  testWidgets('FR-04: pulse can be removed when editing (#3)', (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final at = DateTime(yesterday.year, yesterday.month, yesterday.day, 8);
    final store =
        await _pumpApp(tester, initial: [measurement('p1', at, pulse: 66)]);

    await tester.tap(find.byKey(const Key('measurement-p1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-pulse')), '');
    await _tapSave(tester);

    expect(store.measurements.single.pulse, isNull);
  });

  testWidgets('FR-02: diastolic must be lower than systolic', (tester) async {
    final store = await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('add-button')));
    await tester.pumpAndSettle();
    await _fillForm(tester, sys: '80', dia: '90', pulse: '70');
    await _tapSave(tester);

    expect(find.text('Must be lower than systolic'), findsOneWidget);
    expect(store.measurements, isEmpty);
  });

  testWidgets('FR-02: empty and out-of-range values are rejected',
      (tester) async {
    final store = await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('add-button')));
    await tester.pumpAndSettle();
    await _fillForm(tester, sys: '400', dia: '', pulse: '70');
    await _tapSave(tester);

    expect(find.text('Must be between 50 and 300'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
    expect(store.measurements, isEmpty);
  });

  testWidgets('FR-03: the daily limit offers editing an existing one',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final store = await _pumpApp(tester, initial: [
      measurement('a', today, systolic: 121),
      measurement('b', today.add(const Duration(minutes: 1)), systolic: 122),
      measurement('c', today.add(const Duration(minutes: 2)), systolic: 123),
    ]);

    await tester.tap(find.byKey(const Key('add-button')));
    await tester.pumpAndSettle();
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

  testWidgets('FR-04: edit and delete a measurement', (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final at = DateTime(yesterday.year, yesterday.month, yesterday.day, 7, 30);
    final store = await _pumpApp(tester, initial: [measurement('m1', at)]);

    await tester.tap(find.byKey(const Key('measurement-m1')));
    await tester.pumpAndSettle();
    expect(find.text('Edit measurement'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('field-pulse')), '80');
    await _tapSave(tester);
    expect(store.measurements.single.pulse, 80);
    expect(find.text('80 bpm'), findsOneWidget);

    await tester.tap(find.byKey(const Key('measurement-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();
    expect(store.measurements, isEmpty);
    expect(find.byKey(const Key('log-empty')), findsOneWidget);
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
