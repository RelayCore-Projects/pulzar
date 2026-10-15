import '../app_info.dart';
import 'rules.dart';

/// FR-15: a felhasználó beállításai (v0.5.0).
class AppSettings {
  const AppSettings({
    this.reportName,
    this.referenceEnabled = true,
    this.refSystolic = AppInfo.defaultRefSystolic,
    this.refDiastolic = AppInfo.defaultRefDiastolic,
  });

  /// Név a PDF-en (K-04: opcionális, csak kitöltve jelenik meg).
  final String? reportName;

  /// FR-10: referenciavonal és kiemelés be/ki.
  final bool referenceEnabled;
  final int refSystolic;
  final int refDiastolic;

  static const nameMaxLength = 60;

  /// A referenciaértékek elfogadható tartománya.
  static const refSystolicRange = Range(100, 200);
  static const refDiastolicRange = Range(60, 130);

  /// A grafikon szaggatott vonala – null, ha a referencia ki van kapcsolva.
  int? get systolicReference => referenceEnabled ? refSystolic : null;
  int? get diastolicReference => referenceEnabled ? refDiastolic : null;

  /// „135 / 85 mmHg”
  String get referenceText => '$refSystolic / $refDiastolic mmHg';

  AppSettings copyWith({
    Object? reportName = _unset,
    bool? referenceEnabled,
    int? refSystolic,
    int? refDiastolic,
  }) =>
      AppSettings(
        reportName:
            identical(reportName, _unset) ? this.reportName : reportName as String?,
        referenceEnabled: referenceEnabled ?? this.referenceEnabled,
        refSystolic: refSystolic ?? this.refSystolic,
        refDiastolic: refDiastolic ?? this.refDiastolic,
      );

  static const _unset = Object();

  // ----- tárolás: kulcs–érték párok (SQLite settings tábla) -----

  static const _kName = 'report_name';
  static const _kRefEnabled = 'reference_enabled';
  static const _kRefSys = 'reference_systolic';
  static const _kRefDia = 'reference_diastolic';

  Map<String, String> toMap() => {
        if (reportName != null) _kName: reportName!,
        _kRefEnabled: referenceEnabled ? '1' : '0',
        _kRefSys: '$refSystolic',
        _kRefDia: '$refDiastolic',
      };

  /// Hiányzó vagy hibás érték esetén az alapérték marad.
  factory AppSettings.fromMap(Map<String, String> map) {
    const d = AppSettings();
    int? number(String key, Range range) {
      final v = int.tryParse(map[key] ?? '');
      return v != null && range.contains(v) ? v : null;
    }

    var sys = number(_kRefSys, refSystolicRange) ?? d.refSystolic;
    var dia = number(_kRefDia, refDiastolicRange) ?? d.refDiastolic;
    if (dia >= sys) {
      sys = d.refSystolic;
      dia = d.refDiastolic;
    }
    final name = normalizeName(map[_kName]);
    return AppSettings(
      reportName: name,
      referenceEnabled: map[_kRefEnabled] != '0',
      refSystolic: sys,
      refDiastolic: dia,
    );
  }

  /// Üres név → null; felesleges szóközök nélkül; legfeljebb [nameMaxLength] karakter.
  static String? normalizeName(String? raw) {
    final text = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return null;
    return text.length > nameMaxLength ? text.substring(0, nameMaxLength) : text;
  }

  /// A beállítási párbeszéd ellenőrzése: hibaüzenet, vagy null.
  static String? validateReference(int? systolic, int? diastolic) {
    if (systolic == null || !refSystolicRange.contains(systolic)) {
      return 'Systolic must be between ${refSystolicRange.min} and ${refSystolicRange.max}';
    }
    if (diastolic == null || !refDiastolicRange.contains(diastolic)) {
      return 'Diastolic must be between ${refDiastolicRange.min} and ${refDiastolicRange.max}';
    }
    if (diastolic >= systolic) return 'Diastolic must be lower than systolic';
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.reportName == reportName &&
      other.referenceEnabled == referenceEnabled &&
      other.refSystolic == refSystolic &&
      other.refDiastolic == refDiastolic;

  @override
  int get hashCode =>
      Object.hash(reportName, referenceEnabled, refSystolic, refDiastolic);
}
