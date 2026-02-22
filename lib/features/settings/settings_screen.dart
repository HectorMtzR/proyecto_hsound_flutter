import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool offlineMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de la app')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Modo offline'),
            value: offlineMode,
            onChanged: (val) => setState(() => offlineMode = val),
          ),
          ListTile(
            title: const Text('Información'),
            leading: const Icon(Icons.info_outline),
            onTap: () => context.push('/info'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            onTap: () {
              context.read<MockRepository>().logout();
            },
          ),
        ],
      ),
    );
  }
}