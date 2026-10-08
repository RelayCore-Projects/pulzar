import 'package:flutter/foundation.dart';

import '../data/measurement_repository.dart';
import '../domain/backup.dart';
import '../domain/rules.dart';
import '../models/measurement.dart';
import '../util/format.dart';
import '../util/uuid.dart';

/// FR-03: a napi korlát túllépése. Az [existing] a nap már rögzített méréseit tartalmazza,
/// hogy a felület felajánlhassa valamelyik szerkesztését.
class DailyLimitExceeded implements Exception {
  const DailyLimitExceeded(this.day, this.existing);

  final DateTime day;
  final List<Measurement> existing;

  @override
  String toString() => 'DailyLimitExceeded(${formatDate(day)})';
}

/// A mérések állapota a memóriában + mentés a tárolóba.
class MeasurementStore extends ChangeNotifier {
  MeasurementStore(
    this._repository, {
    DateTime Function()? clock,
    String Function()? newId,
  })  : _clock = clock ?? DateTime.now,
        _newId = newId ?? generateUuidV4;

  final MeasurementRepository _repository;
  final DateTime Function() _clock;
  final String Function() _newId;

  List<Measurement> _items = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// A legfrissebb elöl.
  List<Measurement> get measurements => List.unmodifiable(_items);

  Future<void> load() async {
    _items = await _repository.loadAll();
    _sort();
    _loaded = true;
    notifyListeners();
  }

  /// A legkorábbi mérés ideje (az „All” időszakhoz), vagy null.
  DateTime? get earliest => _items.isEmpty ? null : _items.last.measuredAt;

  /// Egy nap mérései időrendben.
  List<Measurement> onDay(DateTime day, {String? excludeId}) => _items
      .where((m) => isSameDay(m.measuredAt, day) && m.id != excludeId)
      .toList()
    ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

  Future<Measurement> add({
    required DateTime measuredAt,
    required int systolic,
    required int diastolic,
    int? pulse,
    String? note,
  }) async {
    _checkDailyLimit(measuredAt);
    final now = _clock().toUtc();
    final measurement = Measurement(
      id: _newId(),
      measuredAt: measuredAt,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      note: _cleanNote(note),
      createdAt: now,
      updatedAt: now,
    );
    await _repository.insert(measurement);
    _items.add(measurement);
    _sort();
    notifyListeners();
    return measurement;
  }

  Future<Measurement> update(Measurement edited) async {
    final index = _indexOf(edited.id);
    _checkDailyLimit(edited.measuredAt, excludeId: edited.id);
    final measurement = edited.copyWith(
      note: _cleanNote(edited.note),
      updatedAt: _clock().toUtc(),
    );
    await _repository.update(measurement);
    _items[index] = measurement;
    _sort();
    notifyListeners();
    return measurement;
  }

  /// Logikai törlés (NFR-07).
  Future<void> delete(String id) async {
    final index = _indexOf(id);
    final now = _clock().toUtc();
    final deleted = _items[index].copyWith(deletedAt: now, updatedAt: now);
    await _repository.update(deleted);
    _items.removeAt(index);
    notifyListeners();
  }

  /// Minden sor, a törölteket is beleértve – a mentéshez (FR-13).
  Future<List<Measurement>> allIncludingDeleted() =>
      _repository.loadAllIncludingDeleted();

  /// Visszatöltés előnézete: mi változna.
  Future<MergePlan> planRestore(List<Measurement> incoming) async =>
      planMerge(await _repository.loadAllIncludingDeleted(), incoming);

  /// FR-13: összefésülés. A napi korlátot itt nem ellenőrizzük – ez adat-visszaállítás.
  Future<void> applyRestore(MergePlan plan) async {
    await _repository.applyRestore(
      inserts: plan.toInsert,
      updates: plan.toUpdate,
    );
    await load();
  }

  int _indexOf(String id) {
    final index = _items.indexWhere((m) => m.id == id);
    if (index < 0) throw StateError('Unknown measurement: $id');
    return index;
  }

  void _checkDailyLimit(DateTime measuredAt, {String? excludeId}) {
    final existing = onDay(measuredAt, excludeId: excludeId);
    if (existing.length >= MeasurementRules.maxPerDay) {
      throw DailyLimitExceeded(dateOnly(measuredAt), existing);
    }
  }

  void _sort() => _items.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

  static String? _cleanNote(String? note) {
    final text = note?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
