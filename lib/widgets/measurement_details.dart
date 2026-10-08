import 'package:flutter/material.dart';

import '../models/measurement.dart';
import '../screens/measurement_form_screen.dart';
import '../state/store_scope.dart';
import '../util/format.dart';

/// Törlés megerősítése (FR-04) – a részletek lapról és az űrlapról is.
Future<bool> confirmDeleteMeasurement(BuildContext context, Measurement m) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('delete-dialog'),
      title: const Text('Delete measurement?'),
      content: Text('Delete the measurement from ${formatDateTime(m.measuredAt)}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-delete'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

enum _DetailsAction { edit, delete }

/// Rövid érintésre: a mérés részletei alulról felcsúszó lapon (v0.4.0).
/// Hosszú nyomásra a táblázat közvetlenül a szerkesztést nyitja meg.
Future<void> showMeasurementDetails(BuildContext context, Measurement m) async {
  final store = StoreScope.read(context);
  final messenger = ScaffoldMessenger.of(context);
  final action = await showModalBottomSheet<_DetailsAction>(
    context: context,
    showDragHandle: true,
    builder: (sheet) {
      final theme = Theme.of(sheet);
      final note = m.note;
      return SafeArea(
        child: Padding(
          key: const Key('details-sheet'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatDayHeader(m.measuredAt)} · ${formatTime(m.measuredAt)}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text('${m.systolic} / ${m.diastolic} mmHg',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(m.pulse == null ? 'Pulse: –' : 'Pulse: ${m.pulse} bpm',
                  style: theme.textTheme.bodyLarge),
              if (note != null) ...[
                const SizedBox(height: 12),
                SelectableText(note,
                    key: const Key('details-note'),
                    style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    key: const Key('details-delete'),
                    onPressed: () => Navigator.of(sheet).pop(_DetailsAction.delete),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('details-edit'),
                    onPressed: () => Navigator.of(sheet).pop(_DetailsAction.edit),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _DetailsAction.edit:
      await openMeasurementForm(context, existing: m);
    case _DetailsAction.delete:
      if (!await confirmDeleteMeasurement(context, m)) return;
      await store.delete(m.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Measurement deleted')));
  }
}
