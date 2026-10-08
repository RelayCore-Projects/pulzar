import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/domain/period.dart';
import 'package:pulzar/domain/stats.dart';

import 'helpers/factory.dart';

void main() {
  final today = DateTime(2026, 10, 8, 15, 30);

  group('FR-06 calendar periods', () {
    // 2026-10-08 csütörtök
    test('week: Monday to Sunday', () {
      final p = Period.containing(PeriodKind.week, today);
      expect(p.from, DateTime(2026, 10, 5));
      expect(p.to, DateTime(2026, 10, 11));
      expect(p.title, '5 – 11 October 2026');
      expect(p.contains(DateTime(2026, 10, 5, 0, 0)), isTrue);
      expect(p.contains(DateTime(2026, 10, 11, 23, 59)), isTrue);
      expect(p.contains(DateTime(2026, 10, 4, 23, 59)), isFalse);
      expect(p.contains(DateTime(2026, 10, 12)), isFalse);
    });

    test('week across months and years', () {
      expect(Period.containing(PeriodKind.week, DateTime(2026, 10, 1)).title,
          '28 September – 4 October 2026');
      final newYear = Period.containing(PeriodKind.week, DateTime(2026, 1, 1));
      expect(newYear.from, DateTime(2025, 12, 29));
      expect(newYear.title, '29 December 2025 – 4 January 2026');
    });

    test('month and year', () {
      final m = Period.containing(PeriodKind.month, today);
      expect(m.from, DateTime(2026, 10, 1));
      expect(m.to, DateTime(2026, 10, 31));
      expect(m.title, 'October 2026');
      final feb = Period.containing(PeriodKind.month, DateTime(2028, 2, 10));
      expect(feb.to, DateTime(2028, 2, 29)); // szökőév
      final y = Period.containing(PeriodKind.year, today);
      expect(y.from, DateTime(2026, 1, 1));
      expect(y.to, DateTime(2026, 12, 31));
      expect(y.title, '2026');
    });

    test('previous / next: not into the future, not before the first measurement',
        () {
      final week = Period.containing(PeriodKind.week, today);
      expect(week.next(today), isNull);
      expect(week.previous(null), isNull);
      expect(week.previous(DateTime(2026, 10, 6)), isNull);
      final prev = week.previous(DateTime(2026, 9, 1))!;
      expect(prev.from, DateTime(2026, 9, 28));
      expect(prev.next(today)!.from, DateTime(2026, 10, 5));

      final month = Period.containing(PeriodKind.month, today);
      expect(month.previous(DateTime(2026, 9, 30))!.title, 'September 2026');
      final year = Period.containing(PeriodKind.year, today);
      expect(year.previous(DateTime(2025, 6, 1))!.title, '2025');
    });

    test('All: from the earliest measurement to today, contains everything',
        () {
      final p = Period.containing(PeriodKind.all, today,
          earliest: DateTime(2024, 3, 15, 7, 30), today: today);
      expect(p.from, DateTime(2024, 3, 15));
      expect(p.to, DateTime(2026, 10, 8));
      expect(p.contains(DateTime(2020, 1, 1)), isTrue);
      expect(p.title, 'All measurements');
      expect(p.previous(DateTime(2000)), isNull);
      expect(p.next(today), isNull);
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
