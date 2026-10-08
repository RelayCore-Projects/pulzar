import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/chart_data.dart';
import '../domain/period.dart';
import '../platform/file_access.dart';
import '../state/store_scope.dart';
import '../widgets/bp_chart.dart';
import '../widgets/period_selector.dart';

/// FR-08 – FR-10: szisztolé (piros) és diasztolé (kék) egy grafikonon.
/// Egy pont = egy nap átlaga (évnél egy hét), csak pontok – ADR-011.
class ChartsScreen extends StatelessWidget {
  const ChartsScreen({
    super.key,
    required this.selection,
    required this.onChanged,
  });

  final PeriodSelection selection;
  final ValueChanged<PeriodSelection> onChanged;

  /// Világos és sötét témában is jól látható piros és kék.
  static Color systolicColor(Brightness b) =>
      b == Brightness.dark ? Colors.red.shade300 : Colors.red.shade700;
  static Color diastolicColor(Brightness b) =>
      b == Brightness.dark ? Colors.blue.shade300 : Colors.blue.shade700;

  static String _bucketText(Bucket b) => switch (b) {
        Bucket.day => 'daily',
        Bucket.week => 'weekly',
        Bucket.month => 'monthly',
      };

  static String _unitText(Bucket b) => switch (b) {
        Bucket.day => 'day',
        Bucket.week => 'week',
        Bucket.month => 'month',
      };

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final today = AppServices.of(context).now();
    // Az „All” itt nem választható: ha a Table-ön az volt, az aktuális év látszik
    final effective = selection.kind == PeriodKind.all
        ? PeriodSelection(PeriodKind.year, today)
        : selection;
    final period = Period.of(effective, earliest: store.earliest, today: today);
    final items =
        store.measurements.where((m) => period.contains(m.measuredAt)).toList();
    final bucket = bucketFor(period.kind);
    final aggregates = aggregate(items, bucket);
    final theme = Theme.of(context);
    final sysColor = systolicColor(theme.brightness);
    final diaColor = diastolicColor(theme.brightness);

    Widget legend(Color color, String text, {bool dashed = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: dashed ? 2 : 3,
              color: dashed ? color.withValues(alpha: 0.7) : color,
            ),
            const SizedBox(width: 6),
            Text(text, style: theme.textTheme.bodySmall),
          ],
        );

    return PeriodSwipe(
      key: const Key('period-swipe'),
      period: period,
      today: today,
      earliest: store.earliest,
      onChanged: onChanged,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          PeriodSelector(
            period: period,
            today: today,
            earliest: store.earliest,
            onChanged: onChanged,
            kinds: const [PeriodKind.week, PeriodKind.month, PeriodKind.year],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                key: Key('charts-empty'),
                child: Text('No measurements in this period.'),
              ),
            )
          else
            Card(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                          'Blood pressure (mmHg) – ${_bucketText(bucket)} average',
                          style: theme.textTheme.titleSmall),
                    ),
                    BpChart(
                      key: const Key('chart-bp'),
                      start: period.from,
                      end: period.endExclusive,
                      xLabels: axisLabels(period),
                      series: [
                        ChartSeries(
                          label: 'Systolic',
                          color: sysColor,
                          reference: AppInfo.defaultRefSystolic,
                          points: [
                            for (final a in aggregates)
                              ChartPoint(a.center, a.systolic.average,
                                  min: a.systolic.min, max: a.systolic.max),
                          ],
                        ),
                        ChartSeries(
                          label: 'Diastolic',
                          color: diaColor,
                          reference: AppInfo.defaultRefDiastolic,
                          points: [
                            for (final a in aggregates)
                              ChartPoint(a.center, a.diastolic.average,
                                  min: a.diastolic.min, max: a.diastolic.max),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          legend(sysColor, 'Systolic'),
                          legend(diaColor, 'Diastolic'),
                          legend(theme.colorScheme.onSurfaceVariant,
                              'Dashed: reference '
                              '${AppInfo.defaultRefSystolic} / ${AppInfo.defaultRefDiastolic}',
                              dashed: true),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Text(
                        'Each point is the average of one ${_unitText(bucket)}; '
                        'the faint vertical line shows its lowest and highest value.',
                        key: const Key('chart-caption'),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
