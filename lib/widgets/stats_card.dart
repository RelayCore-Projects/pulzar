import 'package:flutter/material.dart';

import '../domain/stats.dart';

/// FR-07: mérések száma, átlag / minimum / maximum.
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final head = theme.textTheme.labelMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final cell = theme.textTheme.titleMedium
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    TableRow row(String label, Stat? s) => TableRow(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(label, style: theme.textTheme.titleSmall),
          ),
          for (final v in [s?.average.round(), s?.min, s?.max])
            Text(v?.toString() ?? '–', textAlign: TextAlign.end, style: cell),
        ]);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stats.count == 1 ? '1 measurement' : '${stats.count} measurements',
              key: const Key('stats-count'),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.4),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
              },
              children: [
                TableRow(children: [
                  const SizedBox.shrink(),
                  Text('avg', textAlign: TextAlign.end, style: head),
                  Text('min', textAlign: TextAlign.end, style: head),
                  Text('max', textAlign: TextAlign.end, style: head),
                ]),
                row('Systolic', stats.systolic),
                row('Diastolic', stats.diastolic),
                row('Pulse', stats.pulse),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
