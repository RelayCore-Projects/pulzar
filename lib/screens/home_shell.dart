import 'package:flutter/material.dart';

import '../widgets/coming_soon.dart';
import 'log_screen.dart';
import 'measurement_form_screen.dart';
import 'settings_screen.dart';

/// Főképernyő alsó navigációval: Log · Table · Charts
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

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
      1 => const ComingSoon(
          key: Key('placeholder-table'),
          icon: Icons.table_chart,
          description:
              'A table for any period, with averages, minimums and maximums.',
          version: '0.4.0',
        ),
      _ => const ComingSoon(
          key: Key('placeholder-charts'),
          icon: Icons.show_chart,
          description: 'Separate charts for systolic and diastolic values.',
          version: '0.5.0',
        ),
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
