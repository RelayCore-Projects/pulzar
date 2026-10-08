import '../models/measurement.dart';

/// Az adattárolás absztrakciója: az app SQLite-ot használ,
/// a tesztek memóriában tárolnak (ADR-007).
abstract class MeasurementRepository {
  /// Az összes nem törölt mérés.
  Future<List<Measurement>> loadAll();

  Future<void> insert(Measurement measurement);

  /// Teljes sor felülírása (szerkesztés és logikai törlés is).
  Future<void> update(Measurement measurement);
}
