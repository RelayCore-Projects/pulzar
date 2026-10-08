import 'package:pulzar/models/measurement.dart';

/// Kitalált tesztadat – valódi mérés soha ne kerüljön a repóba.
Measurement measurement(
  String id,
  DateTime at, {
  int systolic = 120,
  int diastolic = 80,
  int? pulse = 70,
  String? note,
}) {
  final stamp = DateTime.utc(2026, 1, 1);
  return Measurement(
    id: id,
    measuredAt: at,
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse,
    note: note,
    createdAt: stamp,
    updatedAt: stamp,
  );
}
