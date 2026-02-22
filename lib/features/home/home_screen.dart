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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemCount: repo.allTracks.length,
        itemBuilder: (context, index) {
          final track = repo.allTracks[index];
          
          // VERIFICAMOS SI ESTA CANCIÓN ES LA QUE ESTÁ SONANDO
          final isPlaying = repo.currentTrack?.id == track.id;

          return GestureDetector(
            onTap: () => repo.playTrackContext(track, repo.allTracks),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    // Le ponemos un borde rojo a la imagen si está sonando
                    decoration: BoxDecoration(
                      border: isPlaying ? Border.all(color: Colors.redAccent, width: 3) : null,
                    ),
                    child: Image.network(track.coverUrl, fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  track.title, 
                  // Cambiamos el color del texto a rojo si está sonando
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isPlaying ? Colors.redAccent : Colors.white,
                  ), 
                  maxLines: 1
                ),
                Text(track.artist, style: const TextStyle(color: Colors.white54), maxLines: 1),
              ],
            ),
          );
        },
      ),
    );
  }
}