import 'package:flutter/material.dart';

import '../domain/period.dart';

/// FR-06: Week / Month / Year / All, és lapozás ‹ › gombokkal.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.period,
    required this.today,
    required this.earliest,
    required this.onChanged,
  });

  final Period period;
  final DateTime today;
  final DateTime? earliest;
  final ValueChanged<PeriodSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prev = period.previous(earliest);
    final next = period.next(today);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<PeriodKind>(
            key: const Key('period-selector'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: PeriodKind.week, label: Text('Week')),
              ButtonSegment(value: PeriodKind.month, label: Text('Month')),
              ButtonSegment(value: PeriodKind.year, label: Text('Year')),
              ButtonSegment(value: PeriodKind.all, label: Text('All')),
            ],
            selected: {period.kind},
            onSelectionChanged: (s) => onChanged(PeriodSelection(s.first, today)),
          ),
          Row(
            children: [
              IconButton(
                key: const Key('period-previous'),
                tooltip: 'Previous',
                icon: const Icon(Icons.chevron_left),
                onPressed: prev == null
                    ? null
                    : () => onChanged(PeriodSelection(prev.kind, prev.from)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      period.title,
                      key: const Key('period-title'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (period.kind == PeriodKind.all)
                      Text(
                        period.range,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('period-next'),
                tooltip: 'Next',
                icon: const Icon(Icons.chevron_right),
                onPressed: next == null
                    ? null
                    : () => onChanged(PeriodSelection(next.kind, next.from)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Jobbra húzás: előző időszak, balra húzás: következő (FR-06, v0.4.0).
class PeriodSwipe extends StatelessWidget {
  const PeriodSwipe({
    super.key,
    required this.period,
    required this.today,
    required this.earliest,
    required this.onChanged,
    required this.child,
  });

  final Period period;
  final DateTime today;
  final DateTime? earliest;
  final ValueChanged<PeriodSelection> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        final target = v > 300
            ? period.previous(earliest)
            : (v < -300 ? period.next(today) : null);
        if (target != null) onChanged(PeriodSelection(target.kind, target.from));
      },
      child: child,
    );
  }
}
