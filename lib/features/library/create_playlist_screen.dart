import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';

class CreatePlaylistScreen extends StatelessWidget {
  const CreatePlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.red[900], // Acento rojo
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Crear nueva playlist', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: 'Nombre de la playlist', border: UnderlineInputBorder()),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(200, 50)),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  context.read<MockRepository>().createPlaylist(nameCtrl.text);
                  context.go('/library');
                }
              },
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}