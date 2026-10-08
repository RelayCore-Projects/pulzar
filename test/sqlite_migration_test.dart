import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pulzar/data/sqlite_measurement_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/factory.dart';

/// NFR-06: az adatbázis-frissítés nem veszíthet adatot.
void main() {
  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pulzar_db_test');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  /// A v0.3.0 sémája pontosan, ahogy a telefonokon létrejött.
  Future<void> createV1Database(String path) async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE measurements (
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
              'CREATE INDEX idx_measurements_measured_at ON measurements (measured_at)');
        },
      ),
    );
    await db.insert('measurements',
        measurement('a', DateTime(2026, 10, 8, 7, 30), pulse: 72, note: 'x').toMap());
    await db.insert(
        'measurements',
        measurement('b', DateTime(2026, 10, 8, 19, 0), pulse: 75)
            .copyWith(deletedAt: DateTime.utc(2026, 10, 8, 20))
            .toMap());
    await db.close();
  }

  test('v1 → v2 migration keeps every row and allows a missing pulse',
      () async {
    final path = p.join(dir.path, 'pulzar.db');
    await createV1Database(path);

    final repo = await SqliteMeasurementRepository.open(path: path);
    final loaded = await repo.loadAll();
    expect(loaded.map((m) => m.id), ['a']); // a törölt nem látszik
    expect(loaded.single.pulse, 72);
    expect(loaded.single.note, 'x');
    expect(loaded.single.measuredAt, DateTime(2026, 10, 8, 7, 30));

    await repo.insert(measurement('c', DateTime(2026, 10, 9, 7, 0), pulse: null));
    await repo.close();

    // a logikailag törölt sor is megmaradt, és a séma verziója 2
    final raw = await databaseFactoryFfi.openDatabase(path);
    expect(await raw.getVersion(), SqliteMeasurementRepository.schemaVersion);
    final rows = await raw.query('measurements', orderBy: 'id');
    expect(rows.map((r) => r['id']), ['a', 'b', 'c']);
    expect(rows.last['pulse'], isNull);
    await raw.close();
  });

  test('a fresh database works with and without pulse', () async {
    final path = p.join(dir.path, 'fresh.db');
    final repo = await SqliteMeasurementRepository.open(path: path);
    await repo.insert(measurement('a', DateTime(2026, 10, 8, 7), pulse: 70));
    await repo.insert(measurement('b', DateTime(2026, 10, 8, 8), pulse: null));
    final loaded = await repo.loadAll();
    expect(loaded.map((m) => m.pulse), [null, 70]); // legfrissebb elöl
    await repo.close();
  });

  test('FR-13: restore runs in one transaction and keeps deleted rows',
      () async {
    final path = p.join(dir.path, 'restore.db');
    final repo = await SqliteMeasurementRepository.open(path: path);
    await repo.insert(measurement('a', DateTime(2026, 10, 8, 7), pulse: 70));
    await repo.applyRestore(
      inserts: [
        measurement('b', DateTime(2026, 10, 8, 8), pulse: null),
        measurement('c', DateTime(2026, 10, 8, 9))
            .copyWith(deletedAt: DateTime.utc(2026, 10, 9)),
      ],
      updates: [measurement('a', DateTime(2026, 10, 8, 7), pulse: 75)],
    );
    expect((await repo.loadAll()).map((m) => m.id), ['b', 'a']);
    final all = await repo.loadAllIncludingDeleted();
    expect(all.map((m) => m.id).toSet(), {'a', 'b', 'c'});
    expect(all.firstWhere((m) => m.id == 'a').pulse, 75);
    await repo.close();
  });
}
