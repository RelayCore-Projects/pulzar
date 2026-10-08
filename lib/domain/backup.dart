import 'dart:convert';

import '../models/measurement.dart';
import '../util/format.dart';

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// FR-13: teljes mentés JSON-fájlba (formátum: docs/01 Specifikáció, 6. pont).
class Backup {
  Backup._();

  static const format = 'pulzar-backup';
  static const formatVersion = 1;
  static const mimeType = 'application/json';

  static String fileName(DateTime now) =>
      'pulzar-backup-${formatIsoDate(now)}.json';

  /// Az összes sor, a logikailag törölteket is beleértve – így a törlés is „átvihető”.
  static String encode(
    Iterable<Measurement> all, {
    required String appVersion,
    required DateTime exportedAt,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'format_version': formatVersion,
      'app_version': appVersion,
      'exported_at': exportedAt.toUtc().toIso8601String(),
      'measurements': [for (final m in all) m.toMap()],
    });
  }

  static List<Measurement> decode(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw const BackupFormatException('The file is not valid JSON.');
    }
    if (root is! Map<String, Object?> || root['format'] != format) {
      throw const BackupFormatException('This file is not a Pulzar backup.');
    }
    final version = root['format_version'];
    if (version is! int || version > formatVersion) {
      throw const BackupFormatException(
          'This backup was made by a newer version of Pulzar. Please update the app.');
    }
    final items = root['measurements'];
    if (items is! List) {
      throw const BackupFormatException('The backup contains no measurements list.');
    }
    final result = <Measurement>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      try {
        final m = Measurement.fromMap(Map<String, Object?>.from(item as Map));
        if (m.id.isEmpty) throw const FormatException('empty id');
        result.add(m);
      } catch (_) {
        throw BackupFormatException('Measurement #${i + 1} is damaged.');
      }
    }
    return result;
  }
}

/// Visszatöltés összefésüléssel: azonos azonosítónál a később módosított marad.
class MergePlan {
  const MergePlan(this.toInsert, this.toUpdate, this.unchanged);

  final List<Measurement> toInsert;
  final List<Measurement> toUpdate;
  final int unchanged;

  bool get hasChanges => toInsert.isNotEmpty || toUpdate.isNotEmpty;
}

MergePlan planMerge(
  Iterable<Measurement> existing,
  Iterable<Measurement> incoming,
) {
  final current = {for (final m in existing) m.id: m};
  final latestIncoming = <String, Measurement>{};
  for (final m in incoming) {
    final seen = latestIncoming[m.id];
    if (seen == null || m.updatedAt.isAfter(seen.updatedAt)) {
      latestIncoming[m.id] = m;
    }
  }
  final inserts = <Measurement>[];
  final updates = <Measurement>[];
  var unchanged = 0;
  for (final m in latestIncoming.values) {
    final e = current[m.id];
    if (e == null) {
      inserts.add(m);
    } else if (m.updatedAt.isAfter(e.updatedAt)) {
      updates.add(m);
    } else {
      unchanged++;
    }
  }
  return MergePlan(inserts, updates, unchanged);
}
