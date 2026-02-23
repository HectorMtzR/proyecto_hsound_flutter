import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de canciones'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/settings')),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        // 1. Agregamos childAspectRatio para hacer la tarjeta más alta y dar espacio al texto
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          crossAxisSpacing: 16, 
          mainAxisSpacing: 16,
          childAspectRatio: 0.75, // Para ajustar el ratio que ocupa la imagen, se movio para que el cover se vea cuadrado.
        ),
        itemCount: repo.allTracks.length,
        itemBuilder: (context, index) {
          final track = repo.allTracks[index];
          final isPlaying = repo.currentTrack?.id == track.id;

          return GestureDetector(
            onTap: () => repo.playTrackContext(track, repo.allTracks),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quitamos Expanded y usamos AspectRatio 1:1 para forzar el cuadrado
                AspectRatio(
                  aspectRatio: 1, 
                  child: Container(
                    decoration: BoxDecoration(
                      border: isPlaying ? Border.all(color: Colors.redAccent, width: 3) : null,
                    ),
                    child: Image.network(track.coverUrl, fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  track.title, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isPlaying ? Colors.redAccent : Colors.white,
                  ), 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Evita errores visuales si el texto es muy largo
                ),
                Text(
                  track.artist, 
                  style: const TextStyle(color: Colors.white54), 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}