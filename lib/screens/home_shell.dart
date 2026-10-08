import 'package:flutter/material.dart';

import '../widgets/coming_soon.dart';
import 'settings_screen.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.body);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget body;
}

/// Főképernyő alsó navigációval: Log · Table · Charts
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = <_Tab>[
    _Tab(
      'Log',
      Icons.list_alt_outlined,
      Icons.list_alt,
      ComingSoon(
        key: Key('placeholder-log'),
        icon: Icons.list_alt,
        description: 'Your measurements will appear here, grouped by day.',
        version: '0.3.0',
      ),
    ),
    _Tab(
      'Table',
      Icons.table_chart_outlined,
      Icons.table_chart,
      ComingSoon(
        key: Key('placeholder-table'),
        icon: Icons.table_chart,
        description:
            'A table for any period, with averages, minimums and maximums.',
        version: '0.4.0',
      ),
    ),
    _Tab(
      'Charts',
      Icons.show_chart,
      Icons.show_chart,
      ComingSoon(
        key: Key('placeholder-charts'),
        icon: Icons.show_chart,
        description: 'Separate charts for systolic and diastolic values.',
        version: '0.5.0',
      ),
    ),
  ];

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(tab.label),
        actions: [
          IconButton(
            key: const Key('settings-button'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: tab.body,
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              key: const Key('add-button'),
              tooltip: 'New measurement',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recording measurements arrives in v0.3.0.'),
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        key: const Key('main-navigation'),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
