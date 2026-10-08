import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/measurement.dart';
import 'measurement_repository.dart';

/// SQLite tároló a telefonon (NFR-02, ADR-002, ADR-007).
class SqliteMeasurementRepository implements MeasurementRepository {
  SqliteMeasurementRepository._(this._db);

  final Database _db;

  static const _table = 'measurements';

  /// Séma verziója. Változásnál növelni kell, és [_migrate]-ben át kell alakítani (NFR-06).
  ///  1 – v0.3.0: első séma
  ///  2 – v0.3.1: a pulzus opcionális (#3)
  static const schemaVersion = 2;

  /// [path] megadása csak teszteknél kell; alapból az app saját adatbázis-mappája.
  static Future<SqliteMeasurementRepository> open({String? path}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'pulzar.db');
    final db = await openDatabase(
      dbPath,
      version: schemaVersion,
      // Az onCreate és az onUpgrade tranzakcióban fut: hiba esetén minden visszaáll.
      onCreate: (db, version) => _createSchema(db),
      onUpgrade: _migrate,
    );
    return SqliteMeasurementRepository._(db);
  }

  Future<void> close() => _db.close();

  static Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $_table (
        id          TEXT PRIMARY KEY,
        measured_at TEXT    NOT NULL,
        systolic    INTEGER NOT NULL,
        diastolic   INTEGER NOT NULL,
        pulse       INTEGER,
        note        TEXT,
        created_at  TEXT    NOT NULL,
        updated_at  TEXT    NOT NULL,
        deleted_at  TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_measurements_measured_at ON $_table (measured_at)',
    );
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    if (from < 2) {
      // v1 → v2: a pulse oszlopról lekerül a NOT NULL. SQLite-ban ez csak
      // a tábla újraépítésével megy: átnevezés → új tábla → adatok átmásolása → régi törlése.
      const columns = 'id, measured_at, systolic, diastolic, pulse, note, '
          'created_at, updated_at, deleted_at';
      await db.execute('ALTER TABLE $_table RENAME TO ${_table}_v1');
      await db.execute('DROP INDEX IF EXISTS idx_measurements_measured_at');
      await _createSchema(db);
      await db.execute(
        'INSERT INTO $_table ($columns) SELECT $columns FROM ${_table}_v1',
      );
      await db.execute('DROP TABLE ${_table}_v1');
    }
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
