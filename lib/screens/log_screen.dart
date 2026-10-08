import 'package:flutter/material.dart';

import '../domain/grouping.dart';
import '../models/measurement.dart';
import '../state/store_scope.dart';
import '../util/format.dart';
import 'measurement_form_screen.dart';

/// FR-05: a mérések napokra csoportosítva, a legfrissebb nap felül.
class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    if (!store.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final groups = groupByDay(store.measurements);
    if (groups.isEmpty) return const _EmptyLog();

    final today = dateOnly(DateTime.now());
    return ListView.builder(
      key: const Key('log-list'),
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: groups.length,
      itemBuilder: (context, i) => _DaySection(group: groups[i], today: today),
    );
  }
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const Key('log-empty'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No measurements yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap + to record your first one.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.group, required this.today});

  final DayGroup group;
  final DateTime today;

  String get _label {
    final header = formatDayHeader(group.day);
    if (isSameDay(group.day, today)) return 'Today · $header';
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    if (isSameDay(group.day, yesterday)) return 'Yesterday · $header';
    return header;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              _label,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final m in group.measurements) _MeasurementTile(m: m),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({required this.m});

  final Measurement m;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = m.note;
    return ListTile(
      key: Key('measurement-${m.id}'),
      leading: Text(formatTime(m.measuredAt), style: theme.textTheme.titleMedium),
      title: Text(
        '${m.systolic} / ${m.diastolic} mmHg',
        style: theme.textTheme.titleLarge,
      ),
      subtitle: note == null
          ? null
          : Text(note, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text('${m.pulse} bpm', style: theme.textTheme.bodyLarge),
      onTap: () => openMeasurementForm(context, existing: m),
    );
  }
}
