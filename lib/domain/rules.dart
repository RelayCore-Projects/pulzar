/// Bevitel ellenőrzése (FR-02) és a napi korlát (FR-03).
class Range {
  const Range(this.min, this.max);

  final int min;
  final int max;

  bool contains(int value) => value >= min && value <= max;
}

class MeasurementRules {
  MeasurementRules._();

  static const systolic = Range(50, 300);
  static const diastolic = Range(30, 200);
  static const pulse = Range(30, 250);
  static const noteMaxLength = 200;

  /// FR-03: kemény korlát (K-02 döntés)
  static const maxPerDay = 3;

  static String? validateNumber(String? raw, Range range) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    final value = int.tryParse(text);
    if (value == null) return 'Enter a whole number';
    if (!range.contains(value)) {
      return 'Must be between ${range.min} and ${range.max}';
    }
    return null;
  }

  /// Üres érték megengedett (pl. pulzus, v0.3.1); ha van, a tartománynak meg kell felelnie.
  static String? validateOptionalNumber(String? raw, Range range) {
    if ((raw?.trim() ?? '').isEmpty) return null;
    return validateNumber(raw, range);
  }

  static String? validateDiastolicAgainstSystolic({
    required int? systolic,
    required int? diastolic,
  }) {
    if (systolic == null || diastolic == null) return null;
    if (diastolic >= systolic) return 'Must be lower than systolic';
    return null;
  }

  static String? validateNotInFuture(DateTime measuredAt, DateTime now) =>
      measuredAt.isAfter(now) ? "The time can't be in the future" : null;
}
