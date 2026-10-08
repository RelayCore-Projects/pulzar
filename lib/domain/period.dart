import '../util/format.dart';

enum PeriodPreset { days7, days30, days90, custom }

/// Megjelenítési / export időszak (FR-06): mindkét végpont napja beleértve.
class Period {
  const Period._(this.preset, this.from, this.to);

  factory Period.preset(PeriodPreset preset, DateTime today) {
    final days = switch (preset) {
      PeriodPreset.days7 => 7,
      PeriodPreset.days30 => 30,
      PeriodPreset.days90 => 90,
      PeriodPreset.custom =>
        throw ArgumentError('Use Period.custom for a custom range'),
    };
    final end = dateOnly(today);
    return Period._(
      preset,
      DateTime(end.year, end.month, end.day - (days - 1)),
      end,
    );
  }

  factory Period.custom(DateTime from, DateTime to) {
    final a = dateOnly(from);
    final b = dateOnly(to);
    return a.isAfter(b)
        ? Period._(PeriodPreset.custom, b, a)
        : Period._(PeriodPreset.custom, a, b);
  }

  final PeriodPreset preset;

  /// Első nap (00:00)
  final DateTime from;

  /// Utolsó nap (dátum; a nap végéig tart)
  final DateTime to;

  /// A következő nap 00:00 – a grafikon időtengelyének vége.
  DateTime get endExclusive => DateTime(to.year, to.month, to.day + 1);

  bool contains(DateTime t) => !t.isBefore(from) && t.isBefore(endExclusive);

  String get label => switch (preset) {
        PeriodPreset.days7 => 'Last 7 days',
        PeriodPreset.days30 => 'Last 30 days',
        PeriodPreset.days90 => 'Last 90 days',
        PeriodPreset.custom => 'Custom period',
      };

  /// 02/10/2026 – 08/10/2026
  String get range => '${formatDate(from)} – ${formatDate(to)}';
}
