import '../models/measurement.dart';
import '../util/format.dart';

class DayGroup {
  const DayGroup(this.day, this.measurements);

  final DateTime day;

  /// Időrendben (korábbi elöl)
  final List<Measurement> measurements;
}

/// FR-05: napokra csoportosítás, a legfrissebb nap elöl.
List<DayGroup> groupByDay(Iterable<Measurement> items) {
  final byDay = <DateTime, List<Measurement>>{};
  for (final m in items) {
    byDay.putIfAbsent(dateOnly(m.measuredAt), () => []).add(m);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days)
      DayGroup(
        day,
        byDay[day]!..sort((a, b) => a.measuredAt.compareTo(b.measuredAt)),
      ),
  ];
}
