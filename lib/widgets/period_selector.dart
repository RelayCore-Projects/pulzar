import 'package:flutter/material.dart';

import '../domain/period.dart';

/// FR-06: időszak-választó – 7 / 30 / 90 nap vagy az összes mérés.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final Period period;
  final ValueChanged<PeriodPreset> onChanged;

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
              ButtonSegment(value: PeriodPreset.all, label: Text('All')),
            ],
            selected: {period.preset},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
          const SizedBox(height: 6),
          Text(
            '${period.label} · ${period.range}',
            key: const Key('period-range'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
