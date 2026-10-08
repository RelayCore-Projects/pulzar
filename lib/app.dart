import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_shell.dart';

class PulzarApp extends StatelessWidget {
  const PulzarApp({super.key});

  static const _seed = Color(0xFF8E2B3C);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
