import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/data/in_memory_measurement_repository.dart';
import 'package:pulzar/models/measurement.dart';
import 'package:pulzar/state/measurement_store.dart';

import 'helpers/factory.dart';

void main() {
  late InMemoryMeasurementRepository repo;
  late MeasurementStore store;
  var counter = 0;

  setUp(() async {
    counter = 0;
    repo = InMemoryMeasurementRepository();
    store = MeasurementStore(
      repo,
      clock: () => DateTime.utc(2026, 10, 8, 12),
      newId: () => 'id${++counter}',
    );
    await store.load();
  });

  Future<Measurement> addAt(DateTime at) => store.add(
        measuredAt: at,
        systolic: 125,
        diastolic: 80,
        pulse: 70,
      );

  test('adds and keeps newest first', () async {
    await addAt(DateTime(2026, 10, 7, 8));
    await addAt(DateTime(2026, 10, 8, 8));
    expect(store.measurements.map((m) => m.id), ['id2', 'id1']);
    expect(repo.rows, hasLength(2));
  });

  test('FR-03: the 4th measurement on a day is rejected', () async {
    await addAt(DateTime(2026, 10, 8, 7));
    await addAt(DateTime(2026, 10, 8, 13));
    await addAt(DateTime(2026, 10, 8, 19));
    await expectLater(
      addAt(DateTime(2026, 10, 8, 22)),
      throwsA(isA<DailyLimitExceeded>()
          .having((e) => e.existing.length, 'existing', 3)
          .having((e) => e.day, 'day', DateTime(2026, 10, 8))),
    );
    expect(store.measurements, hasLength(3));
    // másik napra lehet
    await addAt(DateTime(2026, 10, 9, 7));
    expect(store.measurements, hasLength(4));
  });

  test('FR-03: editing within a full day is allowed', () async {
    await addAt(DateTime(2026, 10, 8, 7));
    await addAt(DateTime(2026, 10, 8, 13));
    final third = await store.add(
        measuredAt: DateTime(2026, 10, 8, 19),
        systolic: 130,
        diastolic: 85,
        pulse: 75);
    final updated = await store.update(third.copyWith(pulse: 90));
    expect(updated.pulse, 90);
    expect(store.measurements, hasLength(3));
  });

  test('FR-03: moving a measurement into a full day is rejected', () async {
    await addAt(DateTime(2026, 10, 8, 7));
    await addAt(DateTime(2026, 10, 8, 13));
    await addAt(DateTime(2026, 10, 8, 19));
    final other = await addAt(DateTime(2026, 10, 7, 8));
    await expectLater(
      store.update(other.copyWith(measuredAt: DateTime(2026, 10, 8, 21))),
      throwsA(isA<DailyLimitExceeded>()),
    );
  });

  test('FR-04: delete is logical and frees a slot', () async {
    await addAt(DateTime(2026, 10, 8, 7));
    await addAt(DateTime(2026, 10, 8, 13));
    await addAt(DateTime(2026, 10, 8, 19));
    await store.delete('id2');
    expect(store.measurements.map((m) => m.id), isNot(contains('id2')));
    expect(repo.rows['id2']!.isDeleted, isTrue);
    await addAt(DateTime(2026, 10, 8, 21));
    expect(store.onDay(DateTime(2026, 10, 8)), hasLength(3));
  });

  test('deleted measurements are not loaded again', () async {
    final seeded = InMemoryMeasurementRepository([
      measurement('a', DateTime(2026, 10, 8, 7)),
      measurement('b', DateTime(2026, 10, 8, 8))
          .copyWith(deletedAt: DateTime.utc(2026, 10, 8, 9)),
    ]);
    final s = MeasurementStore(seeded);
    await s.load();
    expect(s.measurements.map((m) => m.id), ['a']);
  });

  test('note is trimmed, empty note becomes null', () async {
    final a = await store.add(
        measuredAt: DateTime(2026, 10, 8, 7),
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        note: '  left arm  ');
    final b = await store.add(
        measuredAt: DateTime(2026, 10, 8, 8),
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        note: '   ');
    expect(a.note, 'left arm');
    expect(b.note, isNull);
  });
}

