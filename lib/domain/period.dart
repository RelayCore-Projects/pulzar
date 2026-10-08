import '../util/format.dart';

/// FR-06: 7 / 30 / 90 nap vagy az összes mérés (v0.4.0: az egyéni időszak helyett).
enum PeriodPreset { days7, days30, days90, all }

/// Megjelenítési / export időszak: mindkét végpont napja beleértve.
class Period {
  const Period._(this.preset, this.from, this.to);

  /// [earliest]: a legkorábbi mérés ideje – csak az „All” időszakhoz kell.
  factory Period.of(PeriodPreset preset, DateTime today, {DateTime? earliest}) {
    final end = dateOnly(today);
    if (preset == PeriodPreset.all) {
      final start = earliest == null ? end : dateOnly(earliest);
      return Period._(preset, start.isAfter(end) ? end : start, end);
    }
    final days = switch (preset) {
      PeriodPreset.days7 => 7,
      PeriodPreset.days30 => 30,
      _ => 90,
    };
    return Period._(
      preset,
      DateTime(end.year, end.month, end.day - (days - 1)),
      end,
    );
  }

  final PeriodPreset preset;

  /// Első nap (00:00)
  final DateTime from;

  /// Utolsó nap (dátum; a nap végéig tart)
  final DateTime to;

  /// A következő nap 00:00 – a grafikon időtengelyének vége.
  DateTime get endExclusive => DateTime(to.year, to.month, to.day + 1);

  bool contains(DateTime t) =>
      preset == PeriodPreset.all ||
      (!t.isBefore(from) && t.isBefore(endExclusive));

  String get label => switch (preset) {
        PeriodPreset.days7 => 'Last 7 days',
        PeriodPreset.days30 => 'Last 30 days',
        PeriodPreset.days90 => 'Last 90 days',
        PeriodPreset.all => 'All measurements',
      };

  /// 02/10/2026 – 08/10/2026
  String get range => '${formatDate(from)} – ${formatDate(to)}';
}
