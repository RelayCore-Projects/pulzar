import '../models/measurement.dart';

/// Az adattárolás absztrakciója: az app SQLite-ot használ,
/// a tesztek memóriában tárolnak (ADR-007).
abstract class MeasurementRepository {
  /// Az összes nem törölt mérés.
  Future<List<Measurement>> loadAll();

  Future<void> insert(Measurement measurement);

  /// Teljes sor felülírása (szerkesztés és logikai törlés is).
  Future<void> update(Measurement measurement);

  /// Minden sor, a logikailag törölteket is beleértve (mentéshez, FR-13).
  Future<List<Measurement>> loadAllIncludingDeleted();

  /// Visszatöltés egy lépésben (SQLite-ban egy tranzakcióban).
  Future<void> applyRestore({
    required List<Measurement> inserts,
    required List<Measurement> updates,
  });
}
