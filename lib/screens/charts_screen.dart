import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/period.dart';
import '../state/store_scope.dart';
import '../widgets/bp_chart.dart';
import '../widgets/period_selector.dart';

/// FR-08 – FR-10: szisztolé és diasztolé külön grafikonon, azonos időtengellyel.
class ChartsScreen extends StatelessWidget {
  const ChartsScreen({
    super.key,
    required this.period,
    required this.onPeriodChanged,
  });

  final Period period;
  final ValueChanged<Period> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final items =
        store.measurements.where((m) => period.contains(m.measuredAt)).toList();
    final scheme = Theme.of(context).colorScheme;

    Widget chart(String title, Key key, List<ChartPoint> points, int ref, Color color) {
      return Card(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              BpChart(
                key: key,
                points: points,
                start: period.from,
                end: period.endExclusive,
                color: color,
                reference: ref,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PeriodSelector(period: period, onChanged: onPeriodChanged),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              key: Key('charts-empty'),
              child: Text('No measurements in this period.'),
            ),
          )
        else ...[
          chart(
            'Systolic (mmHg)',
            const Key('chart-systolic'),
            [for (final m in items) ChartPoint(m.measuredAt, m.systolic)],
            AppInfo.defaultRefSystolic,
            scheme.primary,
          ),
          chart(
            'Diastolic (mmHg)',
            const Key('chart-diastolic'),
            [for (final m in items) ChartPoint(m.measuredAt, m.diastolic)],
            AppInfo.defaultRefDiastolic,
            scheme.tertiary,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Dashed line: reference value '
              '(${AppInfo.defaultRefSystolic} / ${AppInfo.defaultRefDiastolic} mmHg).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}
