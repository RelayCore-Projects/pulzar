import 'package:flutter/material.dart';

import '../domain/period.dart';
import '../platform/file_access.dart';
import '../state/store_scope.dart';
import 'charts_screen.dart';
import 'export_screen.dart';
import 'measurement_form_screen.dart';
import 'settings_screen.dart';
import 'table_screen.dart';

/// Főképernyő alsó navigációval: Table · Charts (v0.4.0: a Log fül beolvadt a Table-be)
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// A Table és a Charts közös időszaka (alapból az aktuális hét).
  PeriodSelection? _selection;

  void _select(PeriodSelection s) => setState(() => _selection = s);

  static const _titles = ['Table', 'Charts'];

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  /// FR-11: az export alapból az éppen nézett időszakot ajánlja (a mai napig).
  void _openExport(PeriodSelection selection) {
    final today = AppServices.of(context).now();
    final period = Period.of(selection,
        earliest: StoreScope.read(context).earliest, today: today);
    final to = period.to.isAfter(today) ? today : period.to;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExportScreen(initialFrom: period.from, initialTo: to),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection =
        _selection ?? PeriodSelection(PeriodKind.week, AppServices.of(context).now());
    final Widget body = switch (_index) {
      0 => TableScreen(selection: selection, onChanged: _select),
      _ => ChartsScreen(selection: selection, onChanged: _select),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            key: const Key('export-button'),
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _openExport(selection),
          ),
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
