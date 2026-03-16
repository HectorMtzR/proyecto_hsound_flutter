import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();

    // 1. Envolvemos todo en un controlador de pestañas
    return DefaultTabController(
      length: 2, // Le decimos que habrá exactamente 2 pestañas
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
          // 2. LA BARRA DE PESTAÑAS (TabBar)
          bottom: const TabBar(
            indicatorColor: Colors.redAccent, // La rayita de abajo
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Playlists'),
              Tab(text: 'Álbumes'),
            ],
          ),
        ),
        
        // 3. EL CONTENIDO DE LAS PESTAÑAS (TabBarView)
        body: TabBarView(
          children: [
            // --- PESTAÑA 1: TUS PLAYLISTS (Lo que ya tenías) ---
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: repo.userPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = repo.userPlaylists[index];
                return ListTile(
                  contentPadding: const EdgeInsets.only(bottom: 16),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                      image: playlist.coverUrl.isNotEmpty
                          ? DecorationImage(image: NetworkImage(playlist.coverUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: playlist.coverUrl.isEmpty
                        ? const Icon(Icons.music_note, color: Colors.white54)
                        : null,
                  ),
                  title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${playlist.tracks.length} canciones', style: const TextStyle(color: Colors.white54)),
                  onTap: () => context.push('/library/playlist/${playlist.id}'),
                );
              },
            ),

            // --- PESTAÑA 2: TUS ÁLBUMES (La nueva vista en Cuadrícula) ---
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Dos columnas
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7, // Para que el texto quepa debajo de la imagen
              ),
              itemCount: repo.groupedByAlbum.length,
              itemBuilder: (context, index) {
                // Magia de Diccionarios: Extraemos el nombre del álbum (La llave)
                final albumName = repo.groupedByAlbum.keys.elementAt(index);
                // Extraemos las canciones que viven dentro de esa llave
                final albumTracks = repo.groupedByAlbum[albumName]!;
                // Tomamos la portada de la primera canción para representar todo el disco
                final firstTrack = albumTracks.first;

                return GestureDetector(
                  onTap: () {
                    context.push('/library/album/$albumName');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(firstTrack.coverUrl),
                              fit: BoxFit.cover,
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