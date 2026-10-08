import '../models/measurement.dart';

class Stat {
  const Stat(this.average, this.min, this.max);

  final double average;
  final int min;
  final int max;

  static Stat? of(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return null;
    var sum = 0;
    var lo = list.first;
    var hi = list.first;
    for (final v in list) {
      sum += v;
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    return Stat(sum / list.length, lo, hi);
  }
}

/// FR-07: összesítés egy időszakra. A pulzus csak a pulzussal rögzített mérésekből (v0.3.1).
class PeriodStats {
  const PeriodStats(this.count, this.systolic, this.diastolic, this.pulse);

  final int count;
  final Stat? systolic;
  final Stat? diastolic;
  final Stat? pulse;

  factory PeriodStats.of(Iterable<Measurement> items) {
    final list = items.toList();
    return PeriodStats(
      list.length,
      Stat.of(list.map((m) => m.systolic)),
      Stat.of(list.map((m) => m.diastolic)),
      Stat.of(list.map((m) => m.pulse).whereType<int>()),
    );
  }
}
