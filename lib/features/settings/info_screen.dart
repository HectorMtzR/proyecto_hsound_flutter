import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';

/// Pantalla de Información del Sistema y Créditos.
///
/// Muestra los detalles de la versión actual de la aplicación,
/// la cuenta de usuario activa conectada a Firebase y los créditos 
/// del desarrollador del proyecto.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<MockRepository>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Versión de la app', style: TextStyle(color: Colors.white54)),
            const Text('1.0.0 (MVP Final)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            const Text('Cuenta activa', style: TextStyle(color: Colors.white54)),
            Text(user?.email ?? 'Sin sesión', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            const Divider(color: Colors.white24),
            const SizedBox(height: 24),
            
            const Text('Desarrollador', style: TextStyle(color: Colors.white54)),
            const Text('Héctor Martínez Reyes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Ingeniería en Tecnologías de la Información y Negocios Digitales', 
              style: TextStyle(fontSize: 14, color: Colors.white70)
            ),
            const SizedBox(height: 32),
            
            // Easter egg del desarrollador
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_dining, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Si lees esto, felicidades, te picho una memela.', 
                      style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}