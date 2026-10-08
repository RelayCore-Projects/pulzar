import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/grouping.dart';
import '../domain/period.dart';
import '../domain/stats.dart';
import '../models/measurement.dart';
import '../platform/file_access.dart';
import '../state/store_scope.dart';
import '../util/format.dart';
import '../widgets/period_selector.dart';
import '../widgets/stats_card.dart';
import 'measurement_form_screen.dart';

/// FR-06 / FR-07: táblázat az orvosnak – időrendben, napokra bontva, összesítéssel.
/// Az egész nézet egyben görgethető, így fekvő módban is használható (v0.4.0).
class TableScreen extends StatelessWidget {
  const TableScreen({
    super.key,
    required this.selection,
    required this.onChanged,
  });

  final PeriodSelection selection;
  final ValueChanged<PeriodSelection> onChanged;

  static const _flex = [2, 2, 2, 2, 5];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final today = AppServices.of(context).now();
    final period =
        Period.of(selection, earliest: store.earliest, today: today);
    final items =
        store.measurements.where((m) => period.contains(m.measuredAt)).toList();
    final theme = Theme.of(context);

    // napi fejléc + a nap mérései, időrendben (a legkorábbi nap felül)
    final rows = <Object>[];
    for (final group in groupByDay(items).reversed) {
      rows.add(group.day);
      rows.addAll(group.measurements);
    }

    return PeriodSwipe(
      key: const Key('period-swipe'),
      period: period,
      today: today,
      earliest: store.earliest,
      onChanged: onChanged,
      child: CustomScrollView(
      key: const Key('table-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: PeriodSelector(
            period: period,
            today: today,
            earliest: store.earliest,
            onChanged: onChanged,
          ),
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
      ),
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
  const _Row({required this.flex, required this.cells, this.style});

  final List<int> flex;
  final List<String> cells;
  final TextStyle? style;

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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: i >= 1 && i <= 3 ? TextAlign.end : TextAlign.start,
                  style: style,
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
    final note = m.note;

    Widget number(String text, int i, TextStyle? style) => Expanded(
          flex: flex[i],
          child: Text(text, textAlign: TextAlign.end, maxLines: 1, style: style),
        );

    // Koppintásra megnyílik a mérés – ott a teljes megjegyzés is látszik (v0.4.0)
    return InkWell(
      onTap: () => openMeasurementForm(context, existing: m),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: flex[0],
              child: Text(formatTime(m.measuredAt), maxLines: 1, style: base),
            ),
            number('${m.systolic}', 1,
                m.systolic >= AppInfo.defaultRefSystolic ? high : base),
            number('${m.diastolic}', 2,
                m.diastolic >= AppInfo.defaultRefDiastolic ? high : base),
            number(m.pulse?.toString() ?? '–', 3, base),
            Expanded(
              flex: flex[4],
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: note == null
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          Icon(Icons.sticky_note_2_outlined,
                              key: const Key('note-icon'),
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
