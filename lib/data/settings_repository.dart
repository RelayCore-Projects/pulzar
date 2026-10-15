/// FR-15: a beállítások tárolása kulcs–érték párokként.
/// Az app az SQLite adatbázis `settings` táblájába ír (séma v3), a tesztek memóriába.
abstract class SettingsRepository {
  Future<Map<String, String>> loadSettings();

  /// Az összes beállítás felülírása egy lépésben.
  Future<void> saveSettings(Map<String, String> values);
}

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([Map<String, String> initial = const {}])
      : values = Map.of(initial);

  Map<String, String> values;

  @override
  Future<Map<String, String>> loadSettings() async => Map.of(values);

  @override
  Future<void> saveSettings(Map<String, String> values) async {
    this.values = Map.of(values);
  }
}
