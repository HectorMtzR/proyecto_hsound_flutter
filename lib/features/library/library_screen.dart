import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';

/// Pantalla de Biblioteca Principal del usuario.
///
/// Implementa un [DefaultTabController] para navegar entre dos vistas:
/// 1. Playlists: Listado de listas de reproducción creadas por el usuario o el sistema.
/// 2. Álbumes: Vista en cuadrícula agrupando dinámicamente el catálogo por álbum.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tu Biblioteca'),
          backgroundColor: Colors.grey[900],
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/library/create'),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.redAccent, 
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Playlists'),
              Tab(text: 'Álbumes'),
            ],
          ),
        ),
        
        body: TabBarView(
          children: [
            // --- VISTA 1: TUS PLAYLISTS ---
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: repo.userPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = repo.userPlaylists[index];
                
                return ListTile(
                  contentPadding: const EdgeInsets.only(bottom: 16),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: playlist.coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: playlist.coverUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[850],
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.music_note, color: Colors.white54),
                              ),
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note, color: Colors.white54),
                            ),
                    ),
                  ),
                  title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${playlist.tracks.length} canciones', style: const TextStyle(color: Colors.white54)),
                  onTap: () => context.push('/library/playlist/${playlist.id}'),
                  onLongPress: () {
                    // Candado de seguridad para proteger entidades del sistema
                    final nameLower = playlist.name.toLowerCase();
                    if (nameLower.contains('me gusta') || nameLower.contains('mix')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No puedes eliminar las playlists del sistema'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return; 
                    }

                    // Diálogo de confirmación para eliminar
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text('Eliminar Playlist', style: TextStyle(color: Colors.white)),
                        content: Text('¿Seguro que quieres eliminar "${playlist.name}"?', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                          ),
                          TextButton(
                            onPressed: () {
                              repo.deletePlaylist(playlist.id); 
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Playlist eliminada')),
                              );
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // --- VISTA 2: ÁLBUMES EN CUADRÍCULA ---
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7, 
              ),
              itemCount: repo.groupedByAlbum.length,
              itemBuilder: (context, index) {
                final albumName = repo.groupedByAlbum.keys.elementAt(index);
                final albumTracks = repo.groupedByAlbum[albumName]!;
                final firstTrack = albumTracks.first;

                return GestureDetector(
                  onTap: () => context.push('/library/album/$albumName'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[850],
                          ),
                          // Implementación de imagen con escudo de red
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: firstTrack.coverUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(Icons.wifi_off, color: Colors.white54, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        albumName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        firstTrack.artist,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}