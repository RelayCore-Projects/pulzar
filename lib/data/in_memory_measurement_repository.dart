import '../models/measurement.dart';
import 'measurement_repository.dart';

/// Memóriában tároló változat – tesztekhez.
class InMemoryMeasurementRepository implements MeasurementRepository {
  InMemoryMeasurementRepository([Iterable<Measurement> initial = const []]) {
    for (final m in initial) {
      _rows[m.id] = m;
    }
  }

  final _rows = <String, Measurement>{};

  /// Minden sor, a logikailag törölteket is beleértve.
  Map<String, Measurement> get rows => Map.unmodifiable(_rows);

  @override
  Future<List<Measurement>> loadAll() async =>
      _rows.values.where((m) => !m.isDeleted).toList();

  @override
  Future<void> insert(Measurement measurement) async {
    if (_rows.containsKey(measurement.id)) {
      throw StateError('Duplicate id: ${measurement.id}');
    }
    _rows[measurement.id] = measurement;
  }

  @override
  Future<void> update(Measurement measurement) async {
    if (!_rows.containsKey(measurement.id)) {
      throw StateError('Unknown id: ${measurement.id}');
    }
    _rows[measurement.id] = measurement;
  }
}
