import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<MockRepository>().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Información')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Versión de la app', style: TextStyle(color: Colors.white54)),
            const Text('1.0.0 (Mockup)', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            const Text('Cuenta activa', style: TextStyle(color: Colors.white54)),
            Text(user?.email ?? 'Sin sesión', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            const Text('Equipo de desarrollo', style: TextStyle(color: Colors.white54)),
            const Text('Ingeniería UI/UX', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}