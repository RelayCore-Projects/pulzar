import '../models/measurement.dart';
import '../util/format.dart';
import 'chart_data.dart';
import 'settings.dart';
import 'stats.dart';

/// FR-11: a PDF-jelentés tartalma – szabadon választott időszak (dátumtól–dátumig).
/// Tiszta adat, a megjelenítés a lib/export/pdf_report.dart-ban van.
class Report {
  Report({
    required DateTime from,
    required DateTime to,
    required Iterable<Measurement> measurements,
    required this.settings,
    required this.createdAt,
    required this.appVersion,
    this.includeTable = true,
    this.includeChart = true,
  })  : from = dateOnly(from.isAfter(to) ? to : from),
        to = dateOnly(from.isAfter(to) ? from : to) {
    final end = endExclusive;
    items = measurements
        .where((m) => !m.measuredAt.isBefore(this.from) && m.measuredAt.isBefore(end))
        .toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  }

  /// Első nap (00:00)
  final DateTime from;

  /// Utolsó nap (a nap végéig tart)
  final DateTime to;

  final AppSettings settings;
  final DateTime createdAt;
  final String appVersion;
  final bool includeTable;
  final bool includeChart;

  /// Az időszak mérései időrendben (a legkorábbi elöl) – mint az app táblázatában.
  late final List<Measurement> items;

  DateTime get endExclusive => DateTime(to.year, to.month, to.day + 1);

  /// Hány naptári napot fog át (mindkét végét beleértve).
  int get days => daysBetween(from, to) + 1;

  PeriodStats get stats => PeriodStats.of(items);

  /// Egy pont a grafikonon: ≤ 2 hónap napi, ≤ 2 év heti, fölötte havi átlag.
  Bucket get bucket => reportBucket(days);

  List<Aggregate> get aggregates => aggregate(items, bucket);

  List<AxisLabel> get axisLabels => rangeAxisLabels(from, to);

  /// „1 July – 15 October 2026”, egy napnál „15 October 2026”
  String get rangeTitle => from == to
      ? '${from.day} ${formatMonthYear(from)}'
      : formatDayRange(from, to);

  /// pulzar-report-2026-07-01_2026-10-15.pdf
  String get fileName =>
      'pulzar-report-${formatIsoDate(from)}_${formatIsoDate(to)}.pdf';

  static const mimeType = 'application/pdf';
}

/// Naptári napok különbsége, nyári időszámítástól függetlenül.
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

Bucket reportBucket(int days) => days <= 62
    ? Bucket.day
    : days <= 731
        ? Bucket.week
        : Bucket.month;

/// Az időtengely feliratai tetszőleges időszakra, legfeljebb kb. 10 felirat.
List<AxisLabel> rangeAxisLabels(DateTime from, DateTime to) {
  final days = daysBetween(from, to) + 1;
  DateTime noon(DateTime d) => DateTime(d.year, d.month, d.day, 12);
  if (days <= 10) {
    return [
      for (var i = 0; i < days; i++)
        () {
          final d = DateTime(from.year, from.month, from.day + i);
          return AxisLabel(noon(d), '${weekdayShort(d)} ${d.day}');
        }(),
    ];
  }
  if (days <= 92) {
    final step = (days / 8).ceil();
    return [
      for (var i = 0; i < days; i += step)
        () {
          final d = DateTime(from.year, from.month, from.day + i);
          return AxisLabel(noon(d), '${d.day} ${monthShort(d)}');
        }(),
    ];
  }
  // hónapok: a hónap közepén (ha beleesik az időszakba)
  final months = (to.year - from.year) * 12 + to.month - from.month + 1;
  final step = (months / 10).ceil();
  final withYear = from.year != to.year;
  final end = DateTime(to.year, to.month, to.day + 1);
  return [
    for (var i = 0; i < months; i += step)
      for (final d in [DateTime(from.year, from.month + i, 15)])
        if (!d.isBefore(from) && d.isBefore(end))
          AxisLabel(
            d,
            withYear
                ? "${monthShort(d)} '${(d.year % 100).toString().padLeft(2, '0')}"
                : monthShort(d),
          ),
  ];
}
