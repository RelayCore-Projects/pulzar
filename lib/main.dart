import 'package:flutter/material.dart';

import 'app.dart';
import 'data/sqlite_measurement_repository.dart';
import 'state/measurement_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SqliteMeasurementRepository.open();
  final store = MeasurementStore(repository);
  await store.load();
  runApp(PulzarApp(store: store));
}
