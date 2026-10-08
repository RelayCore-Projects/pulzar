import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/measurement.dart';
import 'measurement_repository.dart';

/// SQLite tároló a telefonon (NFR-02, ADR-002, ADR-007).
class SqliteMeasurementRepository implements MeasurementRepository {
  SqliteMeasurementRepository._(this._db);

  final Database _db;

  static const _table = 'measurements';

  /// Séma verziója. Változásnál növelni kell, és onUpgrade-ben migrálni (NFR-06).
  static const schemaVersion = 1;

  static Future<SqliteMeasurementRepository> open({
    String fileName = 'pulzar.db',
  }) async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, fileName),
      version: schemaVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id          TEXT PRIMARY KEY,
            measured_at TEXT    NOT NULL,
            systolic    INTEGER NOT NULL,
            diastolic   INTEGER NOT NULL,
            pulse       INTEGER NOT NULL,
            note        TEXT,
            created_at  TEXT    NOT NULL,
            updated_at  TEXT    NOT NULL,
            deleted_at  TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_measurements_measured_at ON $_table (measured_at)',
        );
      },
    );
    return SqliteMeasurementRepository._(db);
  }

  @override
  Future<List<Measurement>> loadAll() async {
    final rows = await _db.query(
      _table,
      where: 'deleted_at IS NULL',
      orderBy: 'measured_at DESC',
    );
    return rows.map(Measurement.fromMap).toList();
  }

  @override
  Future<void> insert(Measurement measurement) async {
    await _db.insert(
      _table,
      measurement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> update(Measurement measurement) async {
    await _db.update(
      _table,
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }
}
