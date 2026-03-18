import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';

/// Pantalla principal (Inicio) de la aplicación.
///
/// Muestra una cuadrícula (Grid) con todas las canciones disponibles en el catálogo.
/// Implementa animaciones [Hero] en las carátulas para transiciones fluidas hacia 
/// el reproductor de pantalla completa y resalta visualmente la pista actual en reproducción.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de canciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () => context.push('/settings')
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          crossAxisSpacing: 16, 
          mainAxisSpacing: 16,
          childAspectRatio: 0.75, 
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
                AspectRatio(
                  aspectRatio: 1, 
                  child: Hero(
                    tag: 'track_cover_${track.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        border: isPlaying ? Border.all(color: Colors.redAccent, width: 3) : null,
                      ),
                      child: Image.network(
                        track.coverUrl, 
                        fit: BoxFit.cover, 
                        width: double.infinity,
                        // --- ESTO ATRAPA EL ERROR VISUAL DE RED ---
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[850],
                            child: const Icon(Icons.wifi_off, color: Colors.white54, size: 40),
                          );
                        },
                      ),
                    ),
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
                  overflow: TextOverflow.ellipsis, 
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