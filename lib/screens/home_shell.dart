import 'package:flutter/material.dart';

import '../domain/period.dart';
import 'charts_screen.dart';
import 'log_screen.dart';
import 'measurement_form_screen.dart';
import 'settings_screen.dart';
import 'table_screen.dart';

/// Főképernyő alsó navigációval: Log · Table · Charts
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// A Table és a Charts közös időszaka (alapból 30 nap).
  Period _period = Period.preset(PeriodPreset.days30, DateTime.now());

  void _setPeriod(Period p) => setState(() => _period = p);

  static const _titles = ['Log', 'Table', 'Charts'];

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (_index) {
      0 => const LogScreen(),
      1 => TableScreen(period: _period, onPeriodChanged: _setPeriod),
      _ => ChartsScreen(period: _period, onPeriodChanged: _setPeriod),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            key: const Key('settings-button'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: body,
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              key: const Key('add-button'),
              tooltip: 'New measurement',
              onPressed: () => openMeasurementForm(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        key: const Key('main-navigation'),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart),
            label: 'Table',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Charts',
          ),
        ],
      ),
    );
  }
}
