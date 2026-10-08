import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/chart_data.dart';
import '../domain/period.dart';
import '../models/measurement.dart';
import '../platform/file_access.dart';
import '../state/store_scope.dart';
import '../util/format.dart';
import '../widgets/bp_chart.dart';
import '../widgets/measurement_details.dart';
import '../widgets/period_selector.dart';

/// FR-08 – FR-10: szisztolé (piros) és diasztolé (kék) pontok egy grafikonon.
/// Egy pont = egy nap átlaga (évnél egy hét). Koppintásra a nap / hét mérései – ADR-011.
/// (A lefúrás – Show week / Show month – a következő verzióra halasztva, Ö-015.)
class ChartsScreen extends StatefulWidget {
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

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  /// A kiválasztott nap (évnél hét) kezdete.
  DateTime? _selected;

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Új időszak: a kijelölés törlődik, és a nézet a grafikon tetejére ugrik
  /// (lefúrás után is látszik a grafikon).
  void _change(PeriodSelection s) {
    setState(() => _selected = null);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    widget.onChanged(s);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final today = AppServices.of(context).now();
    // Az „All” itt nem választható: ha a Table-ön az volt, az aktuális év látszik
    final effective = widget.selection.kind == PeriodKind.all
        ? PeriodSelection(PeriodKind.year, today)
        : widget.selection;
    final period = Period.of(effective, earliest: store.earliest, today: today);
    final items =
        store.measurements.where((m) => period.contains(m.measuredAt)).toList();
    final bucket = bucketFor(period.kind);
    final aggregates = aggregate(items, bucket);
    final selected = aggregates.where((a) => a.start == _selected).firstOrNull;
    final theme = Theme.of(context);
    final sysColor = ChartsScreen.systolicColor(theme.brightness);
    final diaColor = ChartsScreen.diastolicColor(theme.brightness);
    final dotRadius = switch (period.kind) {
      PeriodKind.week => 5.0,
      PeriodKind.month => 3.5,
      _ => 2.5,
    };

    void onTapTime(DateTime t) {
      final start = bucketStart(t, bucket);
      final hit = aggregates.any((a) => a.start == start);
      setState(() => _selected = hit && _selected != start ? start : null);
    }

    Widget legend(Color color, String text, {bool dashed = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: dashed ? 18 : 10,
              height: dashed ? 2 : 10,
              decoration: BoxDecoration(
                color: dashed ? color.withValues(alpha: 0.7) : color,
                shape: dashed ? BoxShape.rectangle : BoxShape.circle,
              ),
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
      onChanged: _change,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          PeriodSelector(
            period: period,
            today: today,
            earliest: store.earliest,
            onChanged: _change,
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
          else ...[
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
                          'Blood pressure (mmHg) – '
                          '${bucket == Bucket.week ? 'weekly' : 'daily'} average',
                          style: theme.textTheme.titleSmall),
                    ),
                    BpChart(
                      key: const Key('chart-bp'),
                      start: period.from,
                      end: period.endExclusive,
                      xLabels: axisLabels(period),
                      dotRadius: dotRadius,
                      highlight: selected?.center,
                      onTapTime: onTapTime,
                      series: [
                        ChartSeries(
                          label: 'Systolic',
                          color: sysColor,
                          reference: AppInfo.defaultRefSystolic,
                          points: [
                            for (final a in aggregates)
                              ChartPoint(a.center, a.systolic.average),
                          ],
                        ),
                        ChartSeries(
                          label: 'Diastolic',
                          color: diaColor,
                          reference: AppInfo.defaultRefDiastolic,
                          points: [
                            for (final a in aggregates)
                              ChartPoint(a.center, a.diastolic.average),
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
                        'Each point is the average of one '
                        '${bucket == Bucket.week ? 'week' : 'day'}. '
                        'Tap the chart to see the measurements.',
                        key: const Key('chart-caption'),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected != null)
              _SelectionCard(
                aggregate: selected,
                bucket: bucket,
                kind: period.kind,
                measurements: items
                    .where((m) =>
                        !m.measuredAt.isBefore(selected.start) &&
                        m.measuredAt.isBefore(selected.end))
                    .toList()
                  ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt)),
                onClose: () => setState(() => _selected = null),
              ),
          ],
        ],
      ),
    );
  }
}

/// A kiválasztott nap (hét) mérései.
class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.aggregate,
    required this.bucket,
    required this.kind,
    required this.measurements,
    required this.onClose,
  });

  final Aggregate aggregate;
  final Bucket bucket;
  final PeriodKind kind;
  final List<Measurement> measurements;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = bucket == Bucket.week
        ? formatDayRange(aggregate.start,
            aggregate.end.subtract(const Duration(days: 1)))
        : formatDayHeader(aggregate.start);
    return Card(
      key: const Key('chart-selection'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: theme.colorScheme.primary)),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            Text(
              'Average ${aggregate.systolic.average.round()} / '
              '${aggregate.diastolic.average.round()} mmHg · '
              '${aggregate.count} ${aggregate.count == 1 ? 'measurement' : 'measurements'}',
              key: const Key('selection-average'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            for (final m in measurements)
              ListTile(
                key: Key('selection-${m.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  bucket == Bucket.week
                      ? '${weekdayShort(m.measuredAt)} ${formatTime(m.measuredAt)}'
                      : formatTime(m.measuredAt),
                  style: theme.textTheme.bodyMedium,
                ),
                title: Text('${m.systolic} / ${m.diastolic}'
                    '${m.pulse == null ? '' : '   ${m.pulse} bpm'}'),
                subtitle: m.note == null
                    ? null
                    : Text(m.note!, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => showMeasurementDetails(context, m),
              ),
          ],
        ),
      ),
    );
  }
}
