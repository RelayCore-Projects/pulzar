import 'package:flutter/material.dart';

import 'app.dart';
import 'data/sqlite_measurement_repository.dart';
import 'state/measurement_store.dart';
import 'state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SqliteMeasurementRepository.open();
  final store = MeasurementStore(repository);
  final settings = SettingsStore(repository);
  await Future.wait([store.load(), settings.load()]);
  runApp(PulzarApp(store: store, settings: settings));
}
