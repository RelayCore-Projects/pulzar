import '../util/format.dart';

/// FR-06: naptári időszakok (v0.4.0): hét (hétfő–vasárnap), hónap, év, vagy minden mérés.
enum PeriodKind { week, month, year, all }

/// A kiválasztott időszak: fajta + egy nap, ami beleesik.
class PeriodSelection {
  const PeriodSelection(this.kind, this.anchor);

  final PeriodKind kind;
  final DateTime anchor;
}

/// Megjelenítési / export időszak: [from] és [to] napja is beleértve.
class Period {
  const Period._(this.kind, this.from, this.to);

  /// Az [anchor] napot tartalmazó naptári időszak.
  /// Az „All” időszakhoz [earliest] (legkorábbi mérés) és [today] kell.
  factory Period.containing(
    PeriodKind kind,
    DateTime anchor, {
    DateTime? earliest,
    DateTime? today,
  }) {
    final a = dateOnly(anchor);
    switch (kind) {
      case PeriodKind.week:
        final monday = DateTime(a.year, a.month, a.day - (a.weekday - 1));
        return Period._(kind, monday,
            DateTime(monday.year, monday.month, monday.day + 6));
      case PeriodKind.month:
        return Period._(kind, DateTime(a.year, a.month, 1),
            DateTime(a.year, a.month + 1, 0));
      case PeriodKind.year:
        return Period._(kind, DateTime(a.year, 1, 1), DateTime(a.year, 12, 31));
      case PeriodKind.all:
        final end = dateOnly(today ?? anchor);
        final start = earliest == null ? end : dateOnly(earliest);
        return Period._(kind, start.isAfter(end) ? end : start, end);
    }
  }

  factory Period.of(PeriodSelection s, {DateTime? earliest, DateTime? today}) =>
      Period.containing(s.kind, s.anchor, earliest: earliest, today: today);

  final PeriodKind kind;

  /// Első nap (00:00)
  final DateTime from;

  /// Utolsó nap (dátum; a nap végéig tart)
  final DateTime to;

  /// A következő nap 00:00 – az időtengely vége.
  DateTime get endExclusive => DateTime(to.year, to.month, to.day + 1);

  bool contains(DateTime t) =>
      kind == PeriodKind.all || (!t.isBefore(from) && t.isBefore(endExclusive));

  /// Az előző időszak, ha van korábbi mérés; különben null.
  Period? previous(DateTime? earliest) {
    if (kind == PeriodKind.all || earliest == null) return null;
    if (!dateOnly(earliest).isBefore(from)) return null;
    return Period.containing(kind, from.subtract(const Duration(days: 1)));
  }

  /// A következő időszak, ha nem a jövőben kezdődik; különben null.
  Period? next(DateTime today) {
    if (kind == PeriodKind.all) return null;
    if (endExclusive.isAfter(dateOnly(today))) return null;
    return Period.containing(kind, endExclusive);
  }

  /// „5 – 11 October 2026”, „October 2026”, „2026”, „All measurements”
  String get title => switch (kind) {
        PeriodKind.week => formatDayRange(from, to),
        PeriodKind.month => formatMonthYear(from),
        PeriodKind.year => '${from.year}',
        PeriodKind.all => 'All measurements',
      };

  /// 02/10/2026 – 08/10/2026
  String get range => '${formatDate(from)} – ${formatDate(to)}';
}
