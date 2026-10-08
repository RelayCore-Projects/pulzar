import '../models/measurement.dart';
import '../util/format.dart';
import 'period.dart';
import 'stats.dart';

/// A grafikon egy pontja mit foglal össze (ADR-011).
enum Bucket { day, week, month }

/// Hét és hónap: napi átlag; év: heti átlag; minden mérés: havi átlag.
Bucket bucketFor(PeriodKind kind) => switch (kind) {
      PeriodKind.week || PeriodKind.month => Bucket.day,
      PeriodKind.year => Bucket.week,
      PeriodKind.all => Bucket.month,
    };

DateTime bucketStart(DateTime t, Bucket b) => switch (b) {
      Bucket.day => DateTime(t.year, t.month, t.day),
      Bucket.week => DateTime(t.year, t.month, t.day - (t.weekday - 1)),
      Bucket.month => DateTime(t.year, t.month, 1),
    };

DateTime bucketEnd(DateTime start, Bucket b) => switch (b) {
      Bucket.day => DateTime(start.year, start.month, start.day + 1),
      Bucket.week => DateTime(start.year, start.month, start.day + 7),
      Bucket.month => DateTime(start.year, start.month + 1, 1),
    };

/// Egy nap (hét, hónap) összesítése: átlag és a legkisebb / legnagyobb érték.
class Aggregate {
  const Aggregate(this.start, this.end, this.count, this.systolic, this.diastolic);

  final DateTime start;
  final DateTime end;
  final int count;
  final Stat systolic;
  final Stat diastolic;

  /// A pont helye az időtengelyen: az egység közepe.
  DateTime get center =>
      start.add(Duration(milliseconds: end.difference(start).inMilliseconds ~/ 2));
}

List<Aggregate> aggregate(Iterable<Measurement> items, Bucket bucket) {
  final groups = <DateTime, List<Measurement>>{};
  for (final m in items) {
    groups.putIfAbsent(bucketStart(m.measuredAt, bucket), () => []).add(m);
  }
  final starts = groups.keys.toList()..sort();
  return [
    for (final s in starts)
      Aggregate(
        s,
        bucketEnd(s, bucket),
        groups[s]!.length,
        Stat.of(groups[s]!.map((m) => m.systolic))!,
        Stat.of(groups[s]!.map((m) => m.diastolic))!,
      ),
  ];
}

class AxisLabel {
  const AxisLabel(this.time, this.text);

  final DateTime time;
  final String text;
}

/// Az időtengely feliratai az időszak fajtája szerint.
List<AxisLabel> axisLabels(Period p) {
  DateTime noon(DateTime d) => DateTime(d.year, d.month, d.day, 12);
  switch (p.kind) {
    case PeriodKind.week:
      return [
        for (var i = 0; i < 7; i++)
          () {
            final d = DateTime(p.from.year, p.from.month, p.from.day + i);
            return AxisLabel(noon(d), '${weekdayShort(d)} ${d.day}');
          }(),
      ];
    case PeriodKind.month:
      return [
        for (final day in [1, 8, 15, 22, 29])
          if (day <= p.to.day)
            AxisLabel(noon(DateTime(p.from.year, p.from.month, day)), '$day'),
      ];
    case PeriodKind.year:
      return [
        for (var m = 1; m <= 12; m++)
          AxisLabel(DateTime(p.from.year, m, 15), monthShort(DateTime(2000, m))),
      ];
    case PeriodKind.all:
      final months = (p.to.year - p.from.year) * 12 + p.to.month - p.from.month + 1;
      final step = months <= 5 ? 1 : (months / 5).ceil();
      return [
        for (var i = 0; i < months; i += step)
          () {
            final d = DateTime(p.from.year, p.from.month + i, 15);
            return AxisLabel(d,
                "${monthShort(d)} '${(d.year % 100).toString().padLeft(2, '0')}");
          }(),
      ];
  }
}
