import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/period.dart';
import '../domain/stats.dart';
import '../models/measurement.dart';
import '../state/store_scope.dart';
import '../util/format.dart';
import '../widgets/period_selector.dart';
import '../widgets/stats_card.dart';

/// FR-06 / FR-07: táblázat az orvosnak – időrendben, összesítéssel, kiemeléssel.
class TableScreen extends StatelessWidget {
  const TableScreen({
    super.key,
    required this.period,
    required this.onPeriodChanged,
  });

  final Period period;
  final ValueChanged<Period> onPeriodChanged;

  static const _flex = [3, 2, 2, 2, 2, 4];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final items = store.measurements.where((m) => period.contains(m.measuredAt)).toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final theme = Theme.of(context);
    // napok sorszáma a váltakozó háttérhez (egyszer számolva, nagy listán is gyors)
    final dayIndex = <int>[];
    for (var i = 0; i < items.length; i++) {
      dayIndex.add(i == 0
          ? 0
          : dayIndex[i - 1] +
              (isSameDay(items[i].measuredAt, items[i - 1].measuredAt) ? 0 : 1));
    }

    return Column(
      children: [
        PeriodSelector(period: period, onChanged: onPeriodChanged),
        StatsCard(stats: PeriodStats.of(items)),
        if (items.isEmpty)
          const Expanded(
            child: Center(
              key: Key('table-empty'),
              child: Text('No measurements in this period.'),
            ),
          )
        else ...[
          _Row(
            flex: _flex,
            cells: const ['Date', 'Time', 'SYS', 'DIA', 'PUL', 'Note'],
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              key: const Key('table-list'),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final m = items[i];
                // napok váltakozó háttérrel, hogy egy nap mérései összetartozzanak
                return ColoredBox(
                  key: Key('table-row-${m.id}'),
                  color: dayIndex[i].isOdd
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : Colors.transparent,
                  child: _MeasurementRow(m: m, flex: _flex),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.flex, required this.cells, this.style, this.styles});

  final List<int> flex;
  final List<String> cells;
  final TextStyle? style;
  final List<TextStyle?>? styles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flex[i],
              child: Text(
                cells[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: i >= 2 && i <= 4 ? TextAlign.end : TextAlign.start,
                style: styles?[i] ?? style,
              ),
            ),
        ],
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.m, required this.flex});

  final Measurement m;
  final List<int> flex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    // FR-10 / FR-06: a referenciaértéket elérő vagy meghaladó érték kiemelve
    final high = base?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.error,
    );
    return _Row(
      flex: flex,
      cells: [
        formatDate(m.measuredAt),
        formatTime(m.measuredAt),
        '${m.systolic}',
        '${m.diastolic}',
        m.pulse?.toString() ?? '–',
        m.note ?? '',
      ],
      styles: [
        base,
        base,
        m.systolic >= AppInfo.defaultRefSystolic ? high : base,
        m.diastolic >= AppInfo.defaultRefDiastolic ? high : base,
        base,
        theme.textTheme.bodySmall,
      ],
    );
  }
}
