import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/app.dart';
import 'package:pulzar/data/in_memory_measurement_repository.dart';
import 'package:pulzar/domain/backup.dart';
import 'package:pulzar/models/measurement.dart';
import 'package:pulzar/platform/file_access.dart';
import 'package:pulzar/state/measurement_store.dart';
import 'package:pulzar/widgets/bp_chart.dart';

import 'helpers/factory.dart';

class FakeFileAccess implements FileAccess {
  String? savedName;
  Uint8List? saved;
  Uint8List? toOpen;

  @override
  Future<String?> saveFile({
    required String name,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    savedName = name;
    saved = bytes;
    return 'content://fake/$name';
  }

  @override
  Future<Uint8List?> openFile() async => toOpen;
}

Future<MeasurementStore> _pump(
  WidgetTester tester, {
  List<Measurement> initial = const [],
  FileAccess? files,
}) async {
  // telefonméretű képernyő (432×960 logikai pont)
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final store = MeasurementStore(InMemoryMeasurementRepository(initial));
  await store.load();
  await tester.pumpWidget(
    PulzarApp(
      store: store,
      fileAccess: files ?? FakeFileAccess(),
      clock: () => _today,
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Finder _nav(String label) => find.descendant(
      of: find.byKey(const Key('main-navigation')),
      matching: find.text(label),
    );

/// Rögzített „ma”: 2026. október 8., csütörtök – a hét 5-től 11-ig tart.
final _today = DateTime(2026, 10, 8, 18);

DateTime _daysAgo(int days, int hour) =>
    DateTime(_today.year, _today.month, _today.day - days, hour);

void main() {
  List<Measurement> sample() => [
        measurement('t1', _daysAgo(0, 1), systolic: 140, diastolic: 90, pulse: 80),
        measurement('t2', _daysAgo(1, 7), systolic: 120, diastolic: 80, pulse: 60),
        measurement('t3', _daysAgo(2, 7), systolic: 125, diastolic: 82, pulse: null),
        measurement('old', _daysAgo(20, 7), systolic: 130, diastolic: 84, pulse: 70),
      ];

  testWidgets('FR-06/07: table shows the period, statistics and rows',
      (tester) async {
    await _pump(tester, initial: sample());
    await tester.tap(_nav('Table'));
    await tester.pumpAndSettle();

    // alapértelmezés: az aktuális hét (5–11 október) → t1, t2, t3
    expect(find.text('5 – 11 October 2026'), findsOneWidget);
    expect(find.text('3 measurements'), findsOneWidget);
    expect(find.byKey(const Key('table-row-old')), findsNothing);
    expect(find.byKey(const Key('table-day-2026-10-06')), findsOneWidget);

    // a hiányzó pulzus „–”, a referenciát elérő érték kiemelve
    final high = tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('table-row-t1')), matching: find.text('140')));
    expect(high.style?.fontWeight, FontWeight.bold);
    final normal = tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('table-row-t2')), matching: find.text('120')));
    expect(normal.style?.fontWeight, isNot(FontWeight.bold));
    expect(
        find.descendant(
            of: find.byKey(const Key('table-row-t3')), matching: find.text('–')),
        findsOneWidget);

    // a jövőbe nem lehet lapozni
    final next =
        tester.widget<IconButton>(find.byKey(const Key('period-next')));
    expect(next.onPressed, isNull);

    // hónap, majd az előző hónap
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('period-previous')));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('1 measurement'), findsOneWidget);
    expect(find.byKey(const Key('table-row-old')), findsOneWidget);
  });

  testWidgets('FR-08/09/10: one chart, red/blue, daily averages',
      (tester) async {
    await _pump(tester, initial: [
      ...sample(),
      // még két mérés csütörtökön → a napi átlag 135 / 86, tartomány 130–140
      measurement('t1b', _daysAgo(0, 9), systolic: 135, diastolic: 86),
      measurement('t1c', _daysAgo(0, 12), systolic: 130, diastolic: 82),
    ]);
    await tester.tap(_nav('Charts'));
    await tester.pumpAndSettle();

    final painter = tester
        .widget<CustomPaint>(find.descendant(
            of: find.byKey(const Key('chart-bp')),
            matching: find.byType(CustomPaint)))
        .painter! as BpChartPainter;

    expect(painter.series, hasLength(2));
    final sys = painter.series[0];
    final dia = painter.series[1];
    expect(sys.label, 'Systolic');
    // napi pontok: kedd, szerda, csütörtök
    expect(sys.points.map((p) => p.value), [125, 120, 135]);
    expect(sys.points.last.min, 130);
    expect(sys.points.last.max, 140);
    expect(sys.points.first.hasRange, isFalse);
    expect(dia.points.map((p) => p.value.round()), [82, 80, 86]);
    expect(sys.reference, 135);
    expect(dia.reference, 85);
    expect(sys.color, Colors.red.shade700);
    expect(dia.color, Colors.blue.shade700);
    expect(painter.xLabels.map((l) => l.text).first, 'Mon 5');
    expect(find.textContaining('average of one day'), findsOneWidget);
  });

  testWidgets('FR-06: swipe right shows the previous week', (tester) async {
    await _pump(tester, initial: sample());
    await tester.tap(_nav('Charts'));
    await tester.pumpAndSettle();
    expect(find.text('5 – 11 October 2026'), findsOneWidget);

    await tester.fling(
        find.byKey(const Key('period-swipe')), const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('28 September – 4 October 2026'), findsOneWidget);
    expect(find.byKey(const Key('charts-empty')), findsOneWidget);

    await tester.fling(
        find.byKey(const Key('period-swipe')), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('5 – 11 October 2026'), findsOneWidget);
  });

  testWidgets('FR-06: “All” shows every measurement', (tester) async {
    await _pump(tester, initial: [
      ...sample(),
      measurement('ancient', _daysAgo(400, 8), systolic: 150, diastolic: 95),
    ]);
    await tester.tap(_nav('Table'));
    await tester.pumpAndSettle();
    expect(find.text('3 measurements'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('5 measurements'), findsOneWidget);
    expect(find.text('All measurements'), findsOneWidget);
    // a legkorábbi nap van felül
    expect(find.byKey(const Key('table-row-ancient')), findsOneWidget);
  });

  testWidgets('Table scrolls as a whole in landscape', (tester) async {
    await _pump(tester, initial: [
      for (var d = 0; d < 20; d++) measurement('m$d', _daysAgo(d, 8)),
    ]);
    tester.view.physicalSize = const Size(2400, 1080); // fekvő
    await tester.pumpAndSettle();
    await tester.tap(_nav('Table'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stats-count')).hitTestable(), findsOneWidget);
    await tester.drag(find.byKey(const Key('table-scroll')), const Offset(0, -400));
    await tester.pumpAndSettle();
    // az összesítő kigördült, a (legkorábbi napoktól kezdődő) sorok látszanak
    expect(find.byKey(const Key('stats-count')).hitTestable(), findsNothing);
    expect(find.byKey(const Key('table-row-m16')).hitTestable(), findsOneWidget);
  });

  testWidgets('FR-13: save a backup', (tester) async {
    final files = FakeFileAccess();
    await _pump(tester, initial: sample(), files: files);

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-save')));
    await tester.pumpAndSettle();

    expect(files.savedName, startsWith('pulzar-backup-'));
    final restored = Backup.decode(utf8.decode(files.saved!));
    expect(restored, hasLength(4));
    expect(find.text('Backup saved (4 measurements).'), findsOneWidget);
  });

  testWidgets('FR-13: restore shows a preview and merges', (tester) async {
    final files = FakeFileAccess();
    final store = await _pump(tester, initial: [sample().first], files: files);
    files.toOpen = Uint8List.fromList(utf8.encode(Backup.encode(sample(),
        appVersion: 'test', exportedAt: DateTime.utc(2026, 10, 8))));

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-restore')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('restore-preview')), findsOneWidget);
    expect(find.textContaining('New measurements: 3'), findsOneWidget);
    expect(find.textContaining('Already up to date: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-restore')));
    await tester.pumpAndSettle();
    expect(store.measurements, hasLength(4));
  });

  testWidgets('FR-13: a wrong file is rejected with a message', (tester) async {
    final files = FakeFileAccess()
      ..toOpen = Uint8List.fromList(utf8.encode('hello'));
    final store = await _pump(tester, files: files);

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-restore')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('restore-error')), findsOneWidget);
    expect(store.measurements, isEmpty);
  });
}
