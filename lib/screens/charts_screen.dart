import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/period.dart';
import '../state/store_scope.dart';
import '../widgets/bp_chart.dart';
import '../widgets/period_selector.dart';

/// FR-08 – FR-10: szisztolé (piros) és diasztolé (kék) egy grafikonon (v0.4.0).
class ChartsScreen extends StatelessWidget {
  const ChartsScreen({
    super.key,
    required this.preset,
    required this.onPresetChanged,
  });

  final PeriodPreset preset;
  final ValueChanged<PeriodPreset> onPresetChanged;

  /// Világos és sötét témában is jól látható piros és kék.
  static Color systolicColor(Brightness b) =>
      b == Brightness.dark ? Colors.red.shade300 : Colors.red.shade700;
  static Color diastolicColor(Brightness b) =>
      b == Brightness.dark ? Colors.blue.shade300 : Colors.blue.shade700;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final period = Period.of(preset, DateTime.now(), earliest: store.earliest);
    final items =
        store.measurements.where((m) => period.contains(m.measuredAt)).toList();
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PeriodSelector(period: period, onChanged: onPresetChanged),
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
                    child: Text('Blood pressure (mmHg)',
                        style: theme.textTheme.titleSmall),
                  ),
                  BpChart(
                    key: const Key('chart-bp'),
                    start: period.from,
                    end: period.endExclusive,
                    series: [
                      ChartSeries(
                        label: 'Systolic',
                        color: sysColor,
                        reference: AppInfo.defaultRefSystolic,
                        points: [
                          for (final m in items)
                            ChartPoint(m.measuredAt, m.systolic),
                        ],
                      ),
                      ChartSeries(
                        label: 'Diastolic',
                        color: diaColor,
                        reference: AppInfo.defaultRefDiastolic,
                        points: [
                          for (final m in items)
                            ChartPoint(m.measuredAt, m.diastolic),
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
                ],
              ),
            ),
          ),
      ],
    );
  }
}
