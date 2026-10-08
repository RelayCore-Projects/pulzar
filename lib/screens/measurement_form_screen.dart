import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/rules.dart';
import '../models/measurement.dart';
import '../state/measurement_store.dart';
import '../state/store_scope.dart';
import '../util/format.dart';

/// Az űrlap eredménye: üzenet a naplónak, vagy kérés egy másik mérés szerkesztésére (FR-03).
class FormOutcome {
  const FormOutcome.message(this.message) : editInstead = null;
  const FormOutcome.edit(this.editInstead) : message = null;

  final String? message;
  final Measurement? editInstead;
}

/// Megnyitja az új mérés / szerkesztés űrlapot, és megjeleníti az eredményt.
Future<void> openMeasurementForm(
  BuildContext context, {
  Measurement? existing,
}) async {
  // Az await előtt elkérjük, mert a hívó elem (pl. egy törölt sor) közben eltűnhet.
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  var current = existing;
  while (true) {
    final target = current;
    final outcome = await navigator.push<FormOutcome>(
      MaterialPageRoute(
        builder: (_) => MeasurementFormScreen(existing: target),
      ),
    );
    if (outcome == null) return;
    final edit = outcome.editInstead;
    if (edit != null) {
      current = edit;
      continue;
    }
    final message = outcome.message;
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    return;
  }
}

/// FR-01, FR-02, FR-04: új mérés rögzítése, szerkesztés, törlés.
class MeasurementFormScreen extends StatefulWidget {
  const MeasurementFormScreen({super.key, this.existing});

  final Measurement? existing;

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _pulse = TextEditingController();
  final _note = TextEditingController();

  late DateTime _date;
  late TimeOfDay _time;
  String? _dateTimeError;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  DateTime get _measuredAt =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final at = existing?.measuredAt ?? DateTime.now();
    _date = dateOnly(at);
    _time = TimeOfDay(hour: at.hour, minute: at.minute);
    if (existing != null) {
      _systolic.text = '${existing.systolic}';
      _diastolic.text = '${existing.diastolic}';
      _pulse.text = '${existing.pulse}';
      _note.text = existing.note ?? '';
    }
  }

  @override
  void dispose() {
    _systolic.dispose();
    _diastolic.dispose();
    _pulse.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _dateTimeError = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null || !mounted) return;
    setState(() {
      _time = picked;
      _dateTimeError = null;
    });
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final dateTimeError =
        MeasurementRules.validateNotInFuture(_measuredAt, DateTime.now());
    setState(() => _dateTimeError = dateTimeError);
    if (!formOk || dateTimeError != null) return;

    final store = StoreScope.read(context);
    final systolic = int.parse(_systolic.text.trim());
    final diastolic = int.parse(_diastolic.text.trim());
    final pulse = int.parse(_pulse.text.trim());
    final existing = widget.existing;

    setState(() => _saving = true);
    try {
      if (existing == null) {
        await store.add(
          measuredAt: _measuredAt,
          systolic: systolic,
          diastolic: diastolic,
          pulse: pulse,
          note: _note.text,
        );
      } else {
        await store.update(existing.copyWith(
          measuredAt: _measuredAt,
          systolic: systolic,
          diastolic: diastolic,
          pulse: pulse,
          note: _note.text,
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop(FormOutcome.message(
        existing == null ? 'Measurement saved' : 'Measurement updated',
      ));
    } on DailyLimitExceeded catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final choice = await showDialog<Measurement>(
        context: context,
        builder: (_) => DailyLimitDialog(error: e),
      );
      if (!mounted) return;
      if (choice != null) {
        Navigator.of(context).pop(FormOutcome.edit(choice));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('delete-dialog'),
        title: const Text('Delete measurement?'),
        content: Text(
          'Delete the measurement from ${formatDateTime(existing.measuredAt)}?',
        ),
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
    if (confirmed != true) return;
    if (!mounted) return;
    final store = StoreScope.read(context);
    setState(() => _saving = true);
    await store.delete(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop(const FormOutcome.message('Measurement deleted'));
  }

  String? _validateDiastolic(String? value) {
    return MeasurementRules.validateNumber(value, MeasurementRules.diastolic) ??
        MeasurementRules.validateDiastolicAgainstSystolic(
          systolic: int.tryParse(_systolic.text.trim()),
          diastolic: int.tryParse(value?.trim() ?? ''),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit measurement' : 'New measurement'),
        actions: [
          if (_isEdit)
            IconButton(
              key: const Key('delete-button'),
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _confirmDelete,
            ),
          TextButton(
            key: const Key('save-button'),
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('date-button'),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(formatDate(_date)),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('time-button'),
                    icon: const Icon(Icons.schedule),
                    label: Text(timeText),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            if (_dateTimeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _dateTimeError!,
                  key: const Key('datetime-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            _NumberField(
              fieldKey: const Key('field-systolic'),
              controller: _systolic,
              label: 'Systolic',
              unit: 'mmHg',
              autofocus: !_isEdit,
              validator: (v) =>
                  MeasurementRules.validateNumber(v, MeasurementRules.systolic),
            ),
            const SizedBox(height: 16),
            _NumberField(
              fieldKey: const Key('field-diastolic'),
              controller: _diastolic,
              label: 'Diastolic',
              unit: 'mmHg',
              validator: _validateDiastolic,
            ),
            const SizedBox(height: 16),
            _NumberField(
              fieldKey: const Key('field-pulse'),
              controller: _pulse,
              label: 'Pulse',
              unit: 'bpm',
              validator: (v) =>
                  MeasurementRules.validateNumber(v, MeasurementRules.pulse),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('field-note'),
              controller: _note,
              maxLength: MeasurementRules.noteMaxLength,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. after medication, left arm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.unit,
    required this.validator,
    this.autofocus = false,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String unit;
  final FormFieldValidator<String> validator;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

/// FR-03: a napi korlát elérésekor felajánlja a meglévő mérések szerkesztését.
class DailyLimitDialog extends StatelessWidget {
  const DailyLimitDialog({super.key, required this.error});

  final DailyLimitExceeded error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('daily-limit-dialog'),
      title: const Text('Daily limit reached'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'There are already ${MeasurementRules.maxPerDay} measurements on '
            '${formatDate(error.day)}. Choose a different date, '
            'or edit one of them:',
          ),
          const SizedBox(height: 8),
          for (final m in error.existing)
            ListTile(
              key: Key('limit-edit-${m.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: Text(
                '${formatTime(m.measuredAt)}   ${m.systolic} / ${m.diastolic}',
              ),
              subtitle: Text('${m.pulse} bpm'),
              onTap: () => Navigator.of(context).pop(m),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
      ],
    );
  }
}
