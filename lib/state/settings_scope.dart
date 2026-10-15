import 'package:flutter/widgets.dart';

import '../domain/settings.dart';
import 'settings_store.dart';

/// Elérhetővé teszi a [SettingsStore]-t minden képernyő számára.
class SettingsScope extends InheritedNotifier<SettingsStore> {
  const SettingsScope({
    super.key,
    required SettingsStore settings,
    required super.child,
  }) : super(notifier: settings);

  /// Figyeli a változásokat.
  static SettingsStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  /// Csak kiolvas, nem figyel.
  static SettingsStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  /// Rövidítés: az aktuális beállítások, figyelve.
  static AppSettings valueOf(BuildContext context) => of(context).value;
}
