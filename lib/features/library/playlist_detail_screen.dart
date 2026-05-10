import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/models/models.dart';

/// Pantalla de detalles de una lista de reproducción específica.
///
/// Muestra la carátula, el título y la lista de pistas que la componen.
/// Permite reproducir la lista en modo normal o aleatorio, y ofrece un 
/// menú contextual por canción para gestionar las pistas dentro de la lista.
class PlaylistDetailScreen extends StatelessWidget {
  /// Identificador único de la playlist a visualizar.
  final String playlistId;
  
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    
    final playlistIndex = repo.userPlaylists.indexWhere((p) => p.id == playlistId);
    
    // Fallback visual si la playlist fue borrada o no se encuentra en memoria
    if (playlistIndex == -1) {
      return const Scaffold(
        body: Center(child: Text('Playlist no encontrada o eliminada'))
      );
    }
    
    final playlist = repo.userPlaylists[playlistIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          onPressed: () => context.go('/library')
        )
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 200, 
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5), 
                          blurRadius: 15, 
                          offset: const Offset(0, 8)
                        )
                      ],
                    ),
                    child: playlist.coverUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: playlist.coverUrl,
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[850],
                                child: const Icon(Icons.wifi_off, color: Colors.white54, size: 80),
                              ),
                            ),
                          )
                        : const Icon(Icons.music_note, color: Colors.white54, size: 80),
                  ),
                ),
                
                const SizedBox(height: 24),
                Text(
                  playlist.name, 
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
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
                      if (!repo.isShuffle) repo.toggleShuffle();
                      
                      final randomIndex = Random().nextInt(playlist.tracks.length);
                      final randomStartingTrack = playlist.tracks[randomIndex];
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
                final isPlaying = repo.currentTrack?.id == track.id;
                
                return ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: track.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: track.coverUrl,
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[850],
                              child: const Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.wifi_off, color: Colors.white54, size: 24),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                  ),
                  title: Text(
                    track.title, 
                    style: TextStyle(
                      color: isPlaying ? Colors.redAccent : Colors.white,
                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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

  /// Despliega un modal inferior con opciones contextuales para la pista seleccionada.
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
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16), 
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))
              ),
              
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.redAccent),
                title: const Text('Agregar a otra playlist', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPlaylistSelector(context, repo, track);
                },
              ),

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agregada a la fila'))
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Despliega un menú para agregar la pista a una de las listas personalizadas del usuario.
  void _showPlaylistSelector(BuildContext context, MockRepository repo, Track track) {
    // Filtramos las listas por defecto del sistema
    final userCreatedPlaylists = repo.userPlaylists.where(
      (p) => p.id != 'p_likes' && p.id != 'p_1'
    ).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      builder: (ctx) {
        return ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0), 
              child: Text('Selecciona una playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ),
            
            if (userCreatedPlaylists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No has creado ninguna playlist personal aún.', style: TextStyle(color: Colors.white54)),
              ),

            ...userCreatedPlaylists.map((playlist) => ListTile(
              title: Text(playlist.name),
              onTap: () {
                repo.addTrackToPlaylist(playlist.id, track);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Agregada a ${playlist.name}'))
                );
              },
            )),
          ],
        );
      },
    );
  }
}