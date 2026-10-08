import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/domain/chart_data.dart';
import 'package:pulzar/domain/period.dart';

import 'helpers/factory.dart';

void main() {
  test('ADR-011: one point per day – average, minimum, maximum', () {
    final points = aggregate([
      measurement('a', DateTime(2026, 10, 8, 7), systolic: 130, diastolic: 80),
      measurement('b', DateTime(2026, 10, 8, 13), systolic: 140, diastolic: 90),
      measurement('c', DateTime(2026, 10, 8, 19), systolic: 135, diastolic: 85),
      measurement('d', DateTime(2026, 10, 6, 7), systolic: 120, diastolic: 78),
    ], Bucket.day);
    expect(points, hasLength(2));
    expect(points.first.start, DateTime(2026, 10, 6));
    expect(points.first.count, 1);
    final day = points.last;
    expect(day.count, 3);
    expect(day.systolic.average, 135);
    expect(day.systolic.min, 130);
    expect(day.systolic.max, 140);
    expect(day.diastolic.average, 85);
    expect(day.center, DateTime(2026, 10, 8, 12));
  });

  test('buckets: week → day, year → week, all → month', () {
    expect(bucketFor(PeriodKind.week), Bucket.day);
    expect(bucketFor(PeriodKind.month), Bucket.day);
    expect(bucketFor(PeriodKind.year), Bucket.week);
    expect(bucketFor(PeriodKind.all), Bucket.month);
    expect(bucketStart(DateTime(2026, 10, 8, 9), Bucket.week),
        DateTime(2026, 10, 5));
    expect(bucketStart(DateTime(2026, 10, 8, 9), Bucket.month),
        DateTime(2026, 10, 1));
    expect(bucketEnd(DateTime(2026, 12, 1), Bucket.month), DateTime(2027, 1, 1));
  });

  test('weekly averages for a year', () {
    final points = aggregate([
      measurement('a', DateTime(2026, 10, 5, 7), systolic: 120),
      measurement('b', DateTime(2026, 10, 11, 7), systolic: 130),
      measurement('c', DateTime(2026, 10, 12, 7), systolic: 140),
    ], Bucket.week);
    expect(points.map((p) => p.systolic.average), [125, 140]);
  });

  group('axis labels', () {
    final thursday = DateTime(2026, 10, 8);

    test('week: seven days', () {
      final labels = axisLabels(Period.containing(PeriodKind.week, thursday));
      expect(labels.map((l) => l.text),
          ['Mon 5', 'Tue 6', 'Wed 7', 'Thu 8', 'Fri 9', 'Sat 10', 'Sun 11']);
    });

    test('month, year, all', () {
      expect(
          axisLabels(Period.containing(PeriodKind.month, thursday))
              .map((l) => l.text),
          ['1', '8', '15', '22', '29']);
      final year = axisLabels(Period.containing(PeriodKind.year, thursday));
      expect(year, hasLength(12));
      expect(year.first.text, 'Jan');
      final all = axisLabels(Period.containing(PeriodKind.all, thursday,
          earliest: DateTime(2024, 3, 1), today: thursday));
      expect(all.length, lessThanOrEqualTo(6));
      expect(all.first.text, "Mar '24");
    });
  });
}
