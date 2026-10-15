import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_info.dart';
import '../domain/settings.dart';
import '../state/settings_scope.dart';
import 'backup_screen.dart';

/// FR-15 / FR-16: beállítások és névjegy.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: AppInfo.version,
      applicationIcon: const Icon(Icons.favorite_border, size: 40),
      applicationLegalese: AppInfo.legalese,
      children: const [
        SizedBox(height: 16),
        Text(AppInfo.disclaimer, key: Key('disclaimer')),
        SizedBox(height: 8),
        Text(AppInfo.repoUrl),
      ],
    );
  }

  Future<void> _editName(BuildContext context, AppSettings current) async {
    final store = SettingsScope.read(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current.reportName ?? ''),
    );
    if (name == null) return; // mégse
    await store.update(current.copyWith(reportName: AppSettings.normalizeName(name)));
  }

  Future<void> _editReference(BuildContext context, AppSettings current) async {
    final store = SettingsScope.read(context);
    final result = await showDialog<(int, int)>(
      context: context,
      builder: (_) => _ReferenceDialog(
        systolic: current.refSystolic,
        diastolic: current.refDiastolic,
      ),
    );
    if (result == null) return;
    await store.update(
        current.copyWith(refSystolic: result.$1, refDiastolic: result.$2));
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.valueOf(context);
    final theme = Theme.of(context);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          section('PDF report'),
          ListTile(
            key: const Key('name-tile'),
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Name on PDF'),
            subtitle: Text(settings.reportName ?? 'Not set – the PDF has no name'),
            onTap: () => _editName(context, settings),
          ),
          section('Reference values'),
          SwitchListTile(
            key: const Key('reference-switch'),
            secondary: const Icon(Icons.horizontal_rule),
            title: const Text('Show reference values'),
            subtitle: const Text('Dashed lines on the charts and in the PDF'),
            value: settings.referenceEnabled,
            onChanged: (on) => SettingsScope.read(context)
                .update(settings.copyWith(referenceEnabled: on)),
          ),
          ListTile(
            key: const Key('reference-tile'),
            leading: const Icon(Icons.tune),
            enabled: settings.referenceEnabled,
            title: const Text('Systolic / diastolic'),
            subtitle: Text(settings.referenceText),
            onTap: () => _editReference(context, settings),
          ),
          section('Data'),
          ListTile(
            key: const Key('backup-tile'),
            leading: const Icon(Icons.save_alt),
            title: const Text('Backup and restore'),
            subtitle: const Text('Save all measurements to a file, or restore them'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            key: const Key('about-tile'),
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Version: ${AppInfo.version}'),
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('name-dialog'),
      title: const Text('Name on PDF'),
      content: TextField(
        key: const Key('name-field'),
        controller: _controller,
        autofocus: true,
        maxLength: AppSettings.nameMaxLength,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'e.g. your full name',
          helperText: 'Leave empty for no name on the PDF',
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('name-save'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ReferenceDialog extends StatefulWidget {
  const _ReferenceDialog({required this.systolic, required this.diastolic});

  final int systolic;
  final int diastolic;

  @override
  State<_ReferenceDialog> createState() => _ReferenceDialogState();
}

class _ReferenceDialogState extends State<_ReferenceDialog> {
  late final _sys = TextEditingController(text: '${widget.systolic}');
  late final _dia = TextEditingController(text: '${widget.diastolic}');
  String? _error;

  @override
  void dispose() {
    _sys.dispose();
    _dia.dispose();
    super.dispose();
  }

  void _save() {
    final sys = int.tryParse(_sys.text.trim());
    final dia = int.tryParse(_dia.text.trim());
    final error = AppSettings.validateReference(sys, dia);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop((sys!, dia!));
  }

  void _reset() {
    setState(() {
      _sys.text = '${AppInfo.defaultRefSystolic}';
      _dia.text = '${AppInfo.defaultRefDiastolic}';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget field(Key key, TextEditingController c, String label) => Expanded(
          child: TextField(
            key: key,
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(labelText: label, suffixText: 'mmHg'),
          ),
        );

    return AlertDialog(
      key: const Key('reference-dialog'),
      title: const Text('Reference values'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              field(const Key('ref-sys-field'), _sys, 'Systolic'),
              const SizedBox(width: 16),
              field(const Key('ref-dia-field'), _dia, 'Diastolic'),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const Key('reference-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Default: ${AppInfo.defaultRefSystolic} / ${AppInfo.defaultRefDiastolic} mmHg '
            '(home measurement threshold). Your doctor may suggest other values.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('reference-reset'),
          onPressed: _reset,
          child: const Text('Default'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('reference-save'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
