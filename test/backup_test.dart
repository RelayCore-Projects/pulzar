import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/data/in_memory_measurement_repository.dart';
import 'package:pulzar/domain/backup.dart';
import 'package:pulzar/state/measurement_store.dart';

import 'helpers/factory.dart';

void main() {
  final at = DateTime(2026, 10, 8, 7, 30);

  group('FR-13 backup file', () {
    test('round trip keeps every field, including deleted rows', () {
      final items = [
        measurement('a', at, pulse: 72, note: 'left arm'),
        measurement('b', at, pulse: null),
        measurement('c', at).copyWith(deletedAt: DateTime.utc(2026, 10, 9)),
      ];
      final text = Backup.encode(items,
          appVersion: '0.4.0', exportedAt: DateTime.utc(2026, 10, 9, 12));
      expect(text, contains('"format": "pulzar-backup"'));
      final back = Backup.decode(text);
      expect(back.map((m) => m.id), ['a', 'b', 'c']);
      expect(back[0].note, 'left arm');
      expect(back[0].measuredAt, at);
      expect(back[1].pulse, isNull);
      expect(back[2].isDeleted, isTrue);
    });

    test('file name uses the ISO date', () {
      expect(Backup.fileName(DateTime(2026, 10, 8, 23)),
          'pulzar-backup-2026-10-08.json');
    });

    test('rejects files that are not Pulzar backups', () {
      expect(() => Backup.decode('not json'),
          throwsA(isA<BackupFormatException>()));
      expect(() => Backup.decode('{"format": "other"}'),
          throwsA(isA<BackupFormatException>()));
      expect(
          () => Backup.decode(
              '{"format": "pulzar-backup", "format_version": 99, "measurements": []}'),
          throwsA(isA<BackupFormatException>()));
      expect(
          () => Backup.decode(
              '{"format": "pulzar-backup", "format_version": 1, "measurements": [{"id": "x"}]}'),
          throwsA(isA<BackupFormatException>()
              .having((e) => e.message, 'message', contains('#1'))));
    });
  });

  group('FR-13 merge', () {
    final old = DateTime.utc(2026, 10, 1);
    final newer = DateTime.utc(2026, 10, 5);

    test('new rows are added, newer versions replace older ones', () {
      final existing = [
        measurement('a', at).copyWith(updatedAt: old),
        measurement('b', at).copyWith(updatedAt: newer),
      ];
      final incoming = [
        measurement('a', at, pulse: 99).copyWith(updatedAt: newer), // újabb
        measurement('b', at, pulse: 11).copyWith(updatedAt: old), // régebbi
        measurement('c', at), // új
      ];
      final plan = planMerge(existing, incoming);
      expect(plan.toInsert.map((m) => m.id), ['c']);
      expect(plan.toUpdate.map((m) => m.id), ['a']);
      expect(plan.unchanged, 1);
      expect(plan.hasChanges, isTrue);
    });

    test('restoring the same backup twice creates no duplicates', () async {
      final repo = InMemoryMeasurementRepository();
      final store = MeasurementStore(repo);
      await store.load();
      final backup = [measurement('a', at), measurement('b', at)];

      await store.applyRestore(await store.planRestore(backup));
      expect(store.measurements, hasLength(2));

      final second = await store.planRestore(backup);
      expect(second.hasChanges, isFalse);
      expect(second.unchanged, 2);
      await store.applyRestore(second);
      expect(store.measurements, hasLength(2));
    });

    test('a deletion in the backup is applied when it is newer', () async {
      final repo = InMemoryMeasurementRepository(
          [measurement('a', at).copyWith(updatedAt: old)]);
      final store = MeasurementStore(repo);
      await store.load();
      final deleted = measurement('a', at)
          .copyWith(updatedAt: newer, deletedAt: newer);
      await store.applyRestore(await store.planRestore([deleted]));
      expect(store.measurements, isEmpty);
    });

    test('restore does not apply the daily limit (it restores data)', () async {
      final store = MeasurementStore(InMemoryMeasurementRepository());
      await store.load();
      final four = [
        for (var i = 0; i < 4; i++)
          measurement('m$i', DateTime(2026, 10, 8, 6 + i)),
      ];
      await store.applyRestore(await store.planRestore(four));
      expect(store.measurements, hasLength(4));
    });
  });
}
