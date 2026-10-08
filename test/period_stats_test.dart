import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/domain/period.dart';
import 'package:pulzar/domain/stats.dart';

import 'helpers/factory.dart';

void main() {
  final today = DateTime(2026, 10, 8, 15, 30);

  group('FR-06 period', () {
    test('7 days includes today and the 6 days before', () {
      final p = Period.preset(PeriodPreset.days7, today);
      expect(p.from, DateTime(2026, 10, 2));
      expect(p.to, DateTime(2026, 10, 8));
      expect(p.contains(DateTime(2026, 10, 2, 0, 0)), isTrue);
      expect(p.contains(DateTime(2026, 10, 8, 23, 59)), isTrue);
      expect(p.contains(DateTime(2026, 10, 1, 23, 59)), isFalse);
      expect(p.contains(DateTime(2026, 10, 9)), isFalse);
      expect(p.range, '02/10/2026 – 08/10/2026');
      expect(p.label, 'Last 7 days');
    });

    test('30 and 90 days, across month boundaries', () {
      expect(Period.preset(PeriodPreset.days30, today).from,
          DateTime(2026, 9, 9));
      expect(Period.preset(PeriodPreset.days90, today).from,
          DateTime(2026, 7, 11));
    });

    test('custom period is normalised to whole days and ordered', () {
      final p = Period.custom(DateTime(2026, 10, 5, 18), DateTime(2026, 10, 1, 9));
      expect(p.from, DateTime(2026, 10, 1));
      expect(p.to, DateTime(2026, 10, 5));
      expect(p.endExclusive, DateTime(2026, 10, 6));
      expect(p.preset, PeriodPreset.custom);
    });
  });

  group('FR-07 statistics', () {
    test('average, minimum, maximum', () {
      final s = PeriodStats.of([
        measurement('a', today, systolic: 120, diastolic: 80, pulse: 60),
        measurement('b', today, systolic: 140, diastolic: 90, pulse: 80),
        measurement('c', today, systolic: 131, diastolic: 85, pulse: 70),
      ]);
      expect(s.count, 3);
      expect(s.systolic!.average, closeTo(130.33, 0.01));
      expect(s.systolic!.min, 120);
      expect(s.systolic!.max, 140);
      expect(s.diastolic!.average.round(), 85);
      expect(s.pulse!.max, 80);
    });

    test('pulse statistics only from measurements with pulse (v0.3.1)', () {
      final s = PeriodStats.of([
        measurement('a', today, pulse: null),
        measurement('b', today, pulse: 70),
      ]);
      expect(s.count, 2);
      expect(s.pulse!.average, 70);
      final none = PeriodStats.of([measurement('a', today, pulse: null)]);
      expect(none.pulse, isNull);
    });

    test('empty period', () {
      final s = PeriodStats.of([]);
      expect(s.count, 0);
      expect(s.systolic, isNull);
    });
  });
}
