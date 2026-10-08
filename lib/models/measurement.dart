import '../util/format.dart';

/// Egy vérnyomásmérés (adatmodell: docs/01 Specifikáció, 6. pont).
class Measurement {
  const Measurement({
    required this.id,
    required this.measuredAt,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;

  /// A mérés időpontja, helyi időben.
  final DateTime measuredAt;
  final int systolic;
  final int diastolic;

  /// Opcionális (v0.3.1, #3)
  final int? pulse;
  final String? note;

  /// UTC időbélyegek – az összefésülésnél (FR-13) az updatedAt dönt.
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Logikai törlés (NFR-07): a törölt mérés nem látszik, de az adatbázisban marad.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  static const _unset = Object();

  Measurement copyWith({
    DateTime? measuredAt,
    int? systolic,
    int? diastolic,
    Object? pulse = _unset,
    Object? note = _unset,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Measurement(
      id: id,
      measuredAt: measuredAt ?? this.measuredAt,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: identical(pulse, _unset) ? this.pulse : pulse as int?,
      note: identical(note, _unset) ? this.note : note as String?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'measured_at': formatLocalIsoDateTime(measuredAt),
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'note': note,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'deleted_at': deletedAt?.toUtc().toIso8601String(),
      };

  factory Measurement.fromMap(Map<String, Object?> map) {
    final deleted = map['deleted_at'] as String?;
    return Measurement(
      id: map['id']! as String,
      measuredAt: DateTime.parse(map['measured_at']! as String),
      systolic: map['systolic']! as int,
      diastolic: map['diastolic']! as int,
      pulse: map['pulse'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      deletedAt: deleted == null ? null : DateTime.parse(deleted),
    );
  }

  @override
  String toString() =>
      'Measurement($id, ${formatDateTime(measuredAt)}, $systolic/$diastolic, ${pulse ?? '-'})';
}
