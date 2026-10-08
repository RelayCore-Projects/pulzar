import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/backup.dart';
import '../platform/file_access.dart';
import '../state/store_scope.dart';

/// FR-13: teljes mentés és visszatöltés.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    final store = StoreScope.read(context);
    final files = AppServices.of(context).fileAccess;
    setState(() => _busy = true);
    try {
      final all = await store.allIncludingDeleted();
      final now = DateTime.now();
      final json = Backup.encode(all,
          appVersion: AppInfo.version, exportedAt: now);
      final saved = await files.saveFile(
        name: Backup.fileName(now),
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: Backup.mimeType,
      );
      if (!mounted) return;
      if (saved != null) {
        final visible = all.where((m) => !m.isDeleted).length;
        _snack('Backup saved ($visible measurements).');
      }
    } catch (e) {
      if (mounted) _snack('Could not save the backup: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final store = StoreScope.read(context);
    final files = AppServices.of(context).fileAccess;
    setState(() => _busy = true);
    try {
      final bytes = await files.openFile();
      if (bytes == null || !mounted) return;
      MergePlan? planOrNull;
      String? error;
      try {
        final incoming = Backup.decode(utf8.decode(bytes, allowMalformed: true));
        planOrNull = await store.planRestore(incoming);
      } on BackupFormatException catch (e) {
        error = e.message;
      }
      if (!mounted) return;
      final message = error;
      if (message != null || planOrNull == null) {
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            key: const Key('restore-error'),
            title: const Text('Cannot restore'),
            content: Text(message ?? 'Unknown error.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
            ],
          ),
        );
        return;
      }
      final plan = planOrNull;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          key: const Key('restore-preview'),
          title: const Text('Restore backup?'),
          content: Text(plan.hasChanges
              ? 'New measurements: ${plan.toInsert.length}\n'
                  'Newer versions of existing ones: ${plan.toUpdate.length}\n'
                  'Already up to date: ${plan.unchanged}\n\n'
                  'Nothing will be deleted from this phone.'
              : 'Everything in this backup is already on this phone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: Text(plan.hasChanges ? 'Cancel' : 'OK'),
            ),
            if (plan.hasChanges)
              FilledButton(
                key: const Key('confirm-restore'),
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('Restore'),
              ),
          ],
        ),
      );
      if (confirmed != true) return;
      await store.applyRestore(plan);
      if (!mounted) return;
      _snack('Restored: ${plan.toInsert.length} new, ${plan.toUpdate.length} updated.');
    } catch (e) {
      if (mounted) _snack('Could not restore: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup and restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Your measurements are stored only on this phone. Save a backup '
            'regularly – for example to Google Drive or your computer – so you '
            'can restore them on a new phone or after reinstalling the app.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('backup-save'),
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_alt),
            label: const Text('Save backup…'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('backup-restore'),
            onPressed: _busy ? null : _restore,
            icon: const Icon(Icons.restore),
            label: const Text('Restore from backup…'),
          ),
          const SizedBox(height: 24),
          Text(
            'Restoring merges the backup with the measurements already on this '
            'phone: new ones are added, and where both have the same measurement, '
            'the more recently edited version is kept.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
