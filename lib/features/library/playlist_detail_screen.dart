import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/models/models.dart'; 

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    
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
                
                // --- BOTÓN DE REPRODUCCIÓN ALEATORIA ---
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  icon: const Icon(Icons.shuffle, size: 28),
                  label: const Text('Aleatorio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (playlist.tracks.isNotEmpty) {
                      if (!repo.isShuffle) {
                        repo.toggleShuffle();
                      }
                      final randomIndex = Random().nextInt(playlist.tracks.length);
                      final randomStartingTrack = playlist.tracks[randomIndex];
                      repo.playTrackContext(randomStartingTrack, playlist.tracks, playlistId: playlist.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta playlist no tiene canciones aún.')));
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
                final isPlaying = repo.currentTrack?.id == track.id;
                
                return ListTile(
                  leading: Image.network(track.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
                  title: Text(track.title, style: TextStyle(color: isPlaying ? Colors.redAccent : Colors.white)),
                  subtitle: Text(track.artist),
                  // --- CAMBIAMOS EL ÍCONO ESTÁTICO POR UN BOTÓN FUNCIONAL ---
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptionsSheet(context, repo, track, playlist.id),
                  ),
                  onTap: () => repo.playTrackContext(track, playlist.tracks, playlistId: playlist.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM SHEET DE OPCIONES ---
  void _showOptionsSheet(BuildContext context, MockRepository repo, Track track, String currentPlaylistId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(margin: const EdgeInsets.only(top: 8, bottom: 16), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
              
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.redAccent),
                title: const Text('Agregar a playlist', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPlaylistSelector(context, repo, track);
                },
              ),

              // Como ya estamos dentro de una playlist, siempre mostramos la opción de eliminar
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                title: const Text('Eliminar de esta playlist', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  repo.removeTrackFromPlaylist(currentPlaylistId, track);
                  Navigator.pop(ctx);
                },
              ),

              ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.redAccent),
                title: const Text('Agregar a la fila de reproducción', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  repo.addToQueueNext(track);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregada a la fila')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DIÁLOGO PARA SELECCIONAR A QUÉ PLAYLIST AGREGAR ---
  void _showPlaylistSelector(BuildContext context, MockRepository repo, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      builder: (ctx) {
        return ListView(
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Text('Selecciona una playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ...repo.userPlaylists.map((playlist) => ListTile(
              title: Text(playlist.name),
              onTap: () {
                repo.addTrackToPlaylist(playlist.id, track);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agregada a ${playlist.name}')));
              },
            )),
          ],
        );
      },
    );
  }
}