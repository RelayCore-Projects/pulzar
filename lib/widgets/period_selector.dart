import 'package:flutter/material.dart';

import '../domain/period.dart';
import '../util/format.dart';

/// FR-06: időszak-választó – 7 / 30 / 90 nap vagy egyéni.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final Period period;
  final ValueChanged<Period> onChanged;

  Future<void> _select(BuildContext context, PeriodPreset preset) async {
    final today = dateOnly(DateTime.now());
    if (preset != PeriodPreset.custom) {
      onChanged(Period.preset(preset, today));
      return;
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: period.from.isAfter(today) ? today : period.from,
        end: period.to.isAfter(today) ? today : period.to,
      ),
    );
    if (range != null) onChanged(Period.custom(range.start, range.end));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<PeriodPreset>(
            key: const Key('period-selector'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: PeriodPreset.days7, label: Text('7 days')),
              ButtonSegment(value: PeriodPreset.days30, label: Text('30 days')),
              ButtonSegment(value: PeriodPreset.days90, label: Text('90 days')),
              ButtonSegment(value: PeriodPreset.custom, label: Text('Custom')),
            ],
            selected: {period.preset},
            onSelectionChanged: (s) => _select(context, s.first),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '${period.label} · ${period.range}',
                  key: const Key('period-range'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              // a már kiválasztott „Custom” gomb nem reagál újra, ezért külön módosító
              if (period.preset == PeriodPreset.custom)
                TextButton(
                  key: const Key('period-change'),
                  onPressed: () => _select(context, PeriodPreset.custom),
                  child: const Text('Change'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
