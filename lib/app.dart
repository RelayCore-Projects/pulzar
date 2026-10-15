import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'export/pdf_report.dart';
import 'platform/file_access.dart';
import 'screens/home_shell.dart';
import 'state/measurement_store.dart';
import 'state/settings_scope.dart';
import 'state/settings_store.dart';
import 'state/store_scope.dart';

class PulzarApp extends StatelessWidget {
  PulzarApp({
    super.key,
    required this.store,
    SettingsStore? settings,
    this.fileAccess = const ChannelFileAccess(),
    this.clock = DateTime.now,
    this.renderPdf = renderReportPdf,
  }) : settings = settings ?? SettingsStore.inMemory();

  final MeasurementStore store;
  final SettingsStore settings;
  final FileAccess fileAccess;
  final DateTime Function() clock;
  final PdfRenderer renderPdf;

  static const _seed = Color(0xFF8E2B3C);

  @override
  Widget build(BuildContext context) {
    return AppServices(
      fileAccess: fileAccess,
      clock: clock,
      renderPdf: renderPdf,
      child: SettingsScope(
        settings: settings,
        child: StoreScope(
          store: store,
          child: MaterialApp(
            title: 'Pulzar',
            debugShowCheckedModeBanner: false,
            // Angol felület, európai formátumokkal: 24 órás idő, hétfővel kezdődő hét
            locale: const Locale('en', 'GB'),
            supportedLocales: const [Locale('en', 'GB')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(
              colorSchemeSeed: _seed,
              brightness: Brightness.light,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorSchemeSeed: _seed,
              brightness: Brightness.dark,
              useMaterial3: true,
            ),
            themeMode: ThemeMode.system,
            home: const HomeShell(),
          ),
        ),
      ),
    );
  }
}
