import 'package:flutter/widgets.dart';

import 'measurement_store.dart';

/// Elérhetővé teszi a [MeasurementStore]-t minden képernyő számára.
class StoreScope extends InheritedNotifier<MeasurementStore> {
  const StoreScope({
    super.key,
    required MeasurementStore store,
    required super.child,
  }) : super(notifier: store);

  /// Figyeli a változásokat (újraépít, ha a mérések változnak).
  static MeasurementStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// Csak kiolvas, nem figyel (pl. gombnyomásnál).
  static MeasurementStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
