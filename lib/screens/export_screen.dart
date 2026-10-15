import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/report.dart';
import '../platform/file_access.dart';
import '../state/settings_scope.dart';
import '../state/store_scope.dart';
import '../util/format.dart';
import 'settings_screen.dart';

/// FR-11 / FR-14: PDF-jelentés szabadon választott időszakra (dátumtól–dátumig),
/// mentés a rendszer fájlválasztójával, utána megnyitható (és onnan nyomtatható).
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, required this.initialFrom, required this.initialTo});

  /// Alapból az éppen nézett időszak (a mai napnál nem később).
  final DateTime initialFrom;
  final DateTime initialTo;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late DateTime _from = dateOnly(widget.initialFrom);
  late DateTime _to = dateOnly(widget.initialTo);
  bool _table = true;
  bool _chart = true;
  bool _busy = false;

  static final _firstDate = DateTime(2000);

  void _snack(ScaffoldMessengerState messenger, SnackBar bar) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(bar);
  }

  void _setRange(DateTime from, DateTime to) => setState(() {
        _from = dateOnly(from);
        _to = dateOnly(to);
      });

  Future<void> _pickFrom() async {
    final today = dateOnly(AppServices.of(context).now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: _firstDate,
      lastDate: today,
      helpText: 'From',
    );
    if (picked == null || !mounted) return;
    _setRange(picked, picked.isAfter(_to) ? picked : _to);
  }

  Future<void> _pickTo() async {
    final today = dateOnly(AppServices.of(context).now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _to.isAfter(today) ? today : _to,
      firstDate: _firstDate,
      lastDate: today,
      helpText: 'To',
    );
    if (picked == null || !mounted) return;
    _setRange(picked.isBefore(_from) ? picked : _from, picked);
  }

  Future<void> _save() async {
    final services = AppServices.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final report = Report(
      from: _from,
      to: _to,
      measurements: StoreScope.read(context).measurements,
      settings: SettingsScope.read(context).value,
      createdAt: services.now(),
      appVersion: AppInfo.version,
      includeTable: _table,
      includeChart: _chart,
    );
    setState(() => _busy = true);
    try {
      final bytes = await services.renderPdf(report);
      final uri = await services.fileAccess.saveFile(
        name: report.fileName,
        bytes: bytes,
        mimeType: Report.mimeType,
      );
      if (uri == null) return; // a felhasználó megszakította
      _snack(
        messenger,
        SnackBar(
          key: const Key('export-saved'),
          content: Text('PDF saved (${report.items.length} measurements).'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              final ok = await services.fileAccess
                  .viewFile(uri: uri, mimeType: Report.mimeType);
              if (!ok) {
                _snack(messenger,
                    const SnackBar(content: Text('No app found to open PDF files.')));
              }
            },
          ),
        ),
      );
    } catch (e) {
      _snack(messenger, SnackBar(content: Text('Could not create the PDF: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final settings = SettingsScope.valueOf(context);
    final today = dateOnly(AppServices.of(context).now());
    final theme = Theme.of(context);
    final end = DateTime(_to.year, _to.month, _to.day + 1);
    final count = store.measurements
        .where((m) => !m.measuredAt.isBefore(_from) && m.measuredAt.isBefore(end))
        .length;
    final canSave = !_busy && count > 0 && (_table || _chart);

    Widget quick(String key, String label, DateTime from) => ActionChip(
          key: Key('export-quick-$key'),
          label: Text(label),
          onPressed: () => _setRange(from, today),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Export PDF')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListTile(
            key: const Key('export-from'),
            leading: const Icon(Icons.event_outlined),
            title: const Text('From'),
            subtitle: Text(formatDayHeader(_from)),
            onTap: _busy ? null : _pickFrom,
          ),
          ListTile(
            key: const Key('export-to'),
            leading: const Icon(Icons.event),
            title: const Text('To'),
            subtitle: Text(formatDayHeader(_to)),
            onTap: _busy ? null : _pickTo,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                quick('30', 'Last 30 days',
                    DateTime(today.year, today.month, today.day - 29)),
                quick('90', 'Last 3 months',
                    DateTime(today.year, today.month - 3, today.day + 1)),
                quick('all', 'All', store.earliest ?? today),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              count == 1 ? '1 measurement' : '$count measurements',
              key: const Key('export-count'),
              style: theme.textTheme.titleSmall,
            ),
          ),
          const Divider(),
          SwitchListTile(
            key: const Key('export-chart'),
            secondary: const Icon(Icons.show_chart),
            title: const Text('Chart'),
            subtitle: const Text('Average systolic and diastolic values'),
            value: _chart,
            onChanged: _busy || !_table ? null : (v) => setState(() => _chart = v),
          ),
          SwitchListTile(
            key: const Key('export-table'),
            secondary: const Icon(Icons.table_chart_outlined),
            title: const Text('Table'),
            subtitle: const Text('Every measurement with date and time'),
            value: _table,
            onChanged: _busy || !_chart ? null : (v) => setState(() => _table = v),
          ),
          const Divider(),
          ListTile(
            key: const Key('export-settings'),
            leading: const Icon(Icons.badge_outlined),
            title: Text(settings.reportName ?? 'No name on the PDF'),
            subtitle: Text(settings.referenceEnabled
                ? 'Reference: ${settings.referenceText}'
                : 'Reference values are off'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FilledButton.icon(
              key: const Key('export-save'),
              onPressed: canSave ? _save : null,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Save PDF…'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'A4, ready to print. After saving, tap Open to view, print or share it.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
