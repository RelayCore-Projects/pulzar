import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/grouping.dart';
import '../domain/period.dart';
import '../domain/stats.dart';
import '../models/measurement.dart';
import '../state/store_scope.dart';
import '../util/format.dart';
import '../widgets/period_selector.dart';
import '../widgets/stats_card.dart';

/// FR-06 / FR-07: táblázat az orvosnak – időrendben, napokra bontva, összesítéssel.
/// Az egész nézet egyben görgethető, így fekvő módban is használható (v0.4.0).
class TableScreen extends StatelessWidget {
  const TableScreen({
    super.key,
    required this.preset,
    required this.onPresetChanged,
  });

  final PeriodPreset preset;
  final ValueChanged<PeriodPreset> onPresetChanged;

  static const _flex = [2, 2, 2, 2, 5];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final period = Period.of(preset, DateTime.now(), earliest: store.earliest);
    final items =
        store.measurements.where((m) => period.contains(m.measuredAt)).toList();
    final theme = Theme.of(context);

    // napi fejléc + a nap mérései, időrendben (a legkorábbi nap felül)
    final rows = <Object>[];
    for (final group in groupByDay(items).reversed) {
      rows.add(group.day);
      rows.addAll(group.measurements);
    }

    return CustomScrollView(
      key: const Key('table-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: PeriodSelector(period: period, onChanged: onPresetChanged),
        ),
        SliverToBoxAdapter(child: StatsCard(stats: PeriodStats.of(items))),
        if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              key: Key('table-empty'),
              child: Text('No measurements in this period.'),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: _Row(
              flex: _flex,
              cells: const ['Time', 'SYS', 'DIA', 'PUL', 'Note'],
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          SliverList.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              if (row is DateTime) return _DayHeader(day: row);
              final m = row as Measurement;
              return KeyedSubtree(
                key: Key('table-row-${m.id}'),
                child: _MeasurementRow(m: m, flex: _flex),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key('table-day-${formatIsoDate(day)}'),
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Text(
        formatDayHeader(day),
        style: theme.textTheme.titleSmall
            ?.copyWith(color: theme.colorScheme.primary),
      ),
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
              child: Padding(
                padding: EdgeInsets.only(left: i == cells.length - 1 ? 16 : 0),
                child: Text(
                  cells[i],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: i >= 1 && i <= 3 ? TextAlign.end : TextAlign.start,
                  style: styles?[i] ?? style,
                ),
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
    // FR-06 / FR-10: a referenciaértéket elérő vagy meghaladó érték kiemelve
    final high = base?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.error,
    );
    return _Row(
      flex: flex,
      cells: [
        formatTime(m.measuredAt),
        '${m.systolic}',
        '${m.diastolic}',
        m.pulse?.toString() ?? '–',
        m.note ?? '',
      ],
      styles: [
        base,
        m.systolic >= AppInfo.defaultRefSystolic ? high : base,
        m.diastolic >= AppInfo.defaultRefDiastolic ? high : base,
        base,
        theme.textTheme.bodySmall,
      ],
    );
  }
}
