import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';
import 'dart:math';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    
    // Validación por si la playlist está vacía o hubo un error al cargarla
    final playlistIndex = repo.userPlaylists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex == -1) return const Scaffold(body: Center(child: Text('Playlist no encontrada')));
    
    final playlist = repo.userPlaylists[playlistIndex];

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/library'))),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Container(width: 150, height: 150, color: Colors.grey[800], child: const Icon(Icons.album, size: 80, color: Colors.white24)),
                const SizedBox(height: 16),
                Text(playlist.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // --- BOTÓN DE REPRODUCCIÓN PRINCIPAL ---
                // --- BOTÓN DE REPRODUCCIÓN ALEATORIA ---
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  icon: const Icon(Icons.shuffle, size: 28), // Cambiamos el ícono a Shuffle
                  label: const Text('Aleatorio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (playlist.tracks.isNotEmpty) {
                      
                      // 1. Nos aseguramos de que el modo aleatorio global esté encendido
                      if (!repo.isShuffle) {
                        repo.toggleShuffle();
                      }

                      // 2. Elegimos un índice al azar basado en el tamaño de la playlist
                      final randomIndex = Random().nextInt(playlist.tracks.length);
                      final randomStartingTrack = playlist.tracks[randomIndex];

                      // 3. Iniciamos la reproducción con esa canción elegida al azar
                      repo.playTrackContext(randomStartingTrack, playlist.tracks, playlistId: playlist.id);
                      
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Esta playlist no tiene canciones aún.'))
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: playlist.tracks.length,
              itemBuilder: (context, index) {
                final track = playlist.tracks[index];
                // Resaltamos en rojo si es la canción actual
                final isPlaying = repo.currentTrack?.id == track.id;
                
                return ListTile(
                  leading: Image.network(track.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
                  title: Text(track.title, style: TextStyle(color: isPlaying ? Colors.redAccent : Colors.white)),
                  subtitle: Text(track.artist),
                  trailing: const Icon(Icons.more_vert),
                  onTap: () => repo.playTrackContext(track, playlist.tracks, playlistId: playlist.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}