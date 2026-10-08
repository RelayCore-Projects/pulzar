import 'package:flutter/material.dart';

import '../app_info.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: AppInfo.version,
      applicationIcon: const Icon(Icons.favorite_border, size: 40),
      applicationLegalese: AppInfo.legalese,
      children: const [
        SizedBox(height: 16),
        Text(AppInfo.disclaimer, key: Key('disclaimer')),
        SizedBox(height: 8),
        Text(AppInfo.repoUrl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.badge_outlined),
            title: Text('Name on PDF'),
            subtitle: Text('Coming in v0.6.0'),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.horizontal_rule),
            title: Text('Reference values'),
            subtitle: Text(
              '${AppInfo.defaultRefSystolic} / ${AppInfo.defaultRefDiastolic} mmHg'
              ' · configurable in v0.5.0',
            ),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.save_alt),
            title: Text('Backup and restore'),
            subtitle: Text('Coming in v0.6.0'),
            enabled: false,
          ),
          const Divider(),
          ListTile(
            key: const Key('about-tile'),
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Version: ${AppInfo.version}'),
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }
}
