import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';

/// Pantalla de configuración y ajustes de la cuenta.
///
/// Permite al usuario alternar preferencias visuales o funcionales (como el
/// modo offline simulado), acceder a los créditos de la aplicación y 
/// cerrar de forma segura su sesión en el sistema.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Estado local para el switch visual del modo offline
  bool offlineMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de la app'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // --- SECCIÓN DE PREFERENCIAS ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('PREFERENCIAS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Modo offline'),
            subtitle: const Text('Simula la desconexión de red', style: TextStyle(color: Colors.white54, fontSize: 12)),
            activeColor: Colors.redAccent,
            value: offlineMode,
            onChanged: (val) {
              setState(() => offlineMode = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Modo offline activado' : 'Modo offline desactivado')),
              );
            },
          ),
          const Divider(color: Colors.white24),
          
          // --- SECCIÓN DE INFORMACIÓN ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('ACERCA DE', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Información del sistema'),
            leading: const Icon(Icons.info_outline, color: Colors.white),
            onTap: () => context.push('/info'),
          ),
          const Divider(color: Colors.white24),
          
          // --- SECCIÓN DE CUENTA ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('CUENTA', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            onTap: () {
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  /// Muestra un cuadro de diálogo para confirmar el cierre de sesión seguro.
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Cierra el diálogo
              context.read<MockRepository>().logout(); // Dispara el logout global
            },
            child: const Text('Salir', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}