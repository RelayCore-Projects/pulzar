import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/domain/grouping.dart';
import 'package:pulzar/domain/rules.dart';
import 'package:pulzar/models/measurement.dart';
import 'package:pulzar/util/format.dart';
import 'package:pulzar/util/uuid.dart';

import 'helpers/factory.dart';

void main() {
  group('FR-02 validation', () {
    test('required and whole number', () {
      expect(MeasurementRules.validateNumber('', MeasurementRules.systolic),
          'Required');
      expect(MeasurementRules.validateNumber('  ', MeasurementRules.systolic),
          'Required');
      expect(MeasurementRules.validateNumber('12a', MeasurementRules.systolic),
          'Enter a whole number');
    });

    test('systolic 50–300', () {
      const r = MeasurementRules.systolic;
      expect(MeasurementRules.validateNumber('49', r), isNotNull);
      expect(MeasurementRules.validateNumber('50', r), isNull);
      expect(MeasurementRules.validateNumber('300', r), isNull);
      expect(MeasurementRules.validateNumber('301', r),
          'Must be between 50 and 300');
    });

    test('diastolic 30–200, pulse 30–250', () {
      expect(MeasurementRules.validateNumber('29', MeasurementRules.diastolic),
          isNotNull);
      expect(MeasurementRules.validateNumber('200', MeasurementRules.diastolic),
          isNull);
      expect(MeasurementRules.validateNumber('201', MeasurementRules.diastolic),
          isNotNull);
      expect(
          MeasurementRules.validateNumber('30', MeasurementRules.pulse), isNull);
      expect(MeasurementRules.validateNumber('251', MeasurementRules.pulse),
          isNotNull);
    });

    test('pulse is optional, but checked when given (#3)', () {
      const r = MeasurementRules.pulse;
      expect(MeasurementRules.validateOptionalNumber('', r), isNull);
      expect(MeasurementRules.validateOptionalNumber(null, r), isNull);
      expect(MeasurementRules.validateOptionalNumber('72', r), isNull);
      expect(MeasurementRules.validateOptionalNumber('20', r),
          'Must be between 30 and 250');
    });

    test('systolic must be greater than diastolic', () {
      expect(
        MeasurementRules.validateDiastolicAgainstSystolic(
            systolic: 120, diastolic: 80),
        isNull,
      );
      expect(
        MeasurementRules.validateDiastolicAgainstSystolic(
            systolic: 80, diastolic: 80),
        'Must be lower than systolic',
      );
      expect(
        MeasurementRules.validateDiastolicAgainstSystolic(
            systolic: null, diastolic: 80),
        isNull,
      );
    });

    test('time cannot be in the future', () {
      final now = DateTime(2026, 10, 8, 12, 0);
      expect(MeasurementRules.validateNotInFuture(now, now), isNull);
      expect(
        MeasurementRules.validateNotInFuture(
            now.add(const Duration(minutes: 1)), now),
        isNotNull,
      );
    });
  });

  group('formatting (en_GB)', () {
    final d = DateTime(2026, 10, 8, 7, 5);

    test('date, time, header, ISO', () {
      expect(formatDate(d), '08/10/2026');
      expect(formatTime(d), '07:05');
      expect(formatDateTime(d), '08/10/2026 07:05');
      expect(formatDayHeader(d), 'Thursday, 8 October 2026');
      expect(formatIsoDate(d), '2026-10-08');
      expect(formatLocalIsoDateTime(d), '2026-10-08T07:05:00');
    });

    test('same day', () {
      expect(isSameDay(d, DateTime(2026, 10, 8, 23, 59)), isTrue);
      expect(isSameDay(d, DateTime(2026, 10, 9)), isFalse);
    });
  });

  test('FR-05 grouping: newest day first, chronological within a day', () {
    final groups = groupByDay([
      measurement('a', DateTime(2026, 10, 7, 8)),
      measurement('b', DateTime(2026, 10, 8, 19)),
      measurement('c', DateTime(2026, 10, 8, 7)),
    ]);
    expect(groups, hasLength(2));
    expect(groups.first.day, DateTime(2026, 10, 8));
    expect(groups.first.measurements.map((m) => m.id), ['c', 'b']);
    expect(groups.last.measurements.map((m) => m.id), ['a']);
  });

  test('UUID v4 format and uniqueness', () {
    final ids = List.generate(500, (_) => generateUuidV4());
    final pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    expect(ids.every(pattern.hasMatch), isTrue);
    expect(ids.toSet(), hasLength(500));
  });

  test('Measurement survives a database round trip', () {
    final original = Measurement(
      id: 'x',
      measuredAt: DateTime(2026, 10, 8, 7, 30),
      systolic: 128,
      diastolic: 82,
      pulse: 72,
      note: 'left arm',
      createdAt: DateTime.utc(2026, 10, 8, 5, 30),
      updatedAt: DateTime.utc(2026, 10, 8, 6, 0),
      deletedAt: DateTime.utc(2026, 10, 9),
    );
    final copy = Measurement.fromMap(original.toMap());
    expect(copy.id, original.id);
    expect(copy.measuredAt, original.measuredAt);
    expect(copy.measuredAt.isUtc, isFalse);
    expect(copy.systolic, 128);
    expect(copy.diastolic, 82);
    expect(copy.pulse, 72);
    expect(copy.note, 'left arm');
    expect(copy.createdAt, original.createdAt);
    expect(copy.updatedAt, original.updatedAt);
    expect(copy.deletedAt, original.deletedAt);
  });

  test('round trip without pulse (#3)', () {
    final m = measurement('x', DateTime(2026, 10, 8, 7), pulse: null);
    expect(Measurement.fromMap(m.toMap()).pulse, isNull);
  });

  test('copyWith can clear the note', () {
    final m = measurement('x', DateTime(2026, 10, 8), note: 'n');
    expect(m.copyWith(note: null).note, isNull);
    expect(m.copyWith(pulse: 90).note, 'n');
    expect(m.copyWith(pulse: null).pulse, isNull);
  });
}
