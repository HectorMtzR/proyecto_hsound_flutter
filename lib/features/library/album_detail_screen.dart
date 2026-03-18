import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';

/// Pantalla de detalles de un álbum específico.
///
/// Muestra la portada del álbum en un [SliverAppBar] que se encoge 
/// dinámicamente al hacer scroll. Lista todas las pistas agrupadas 
/// bajo este álbum y permite su reproducción en contexto continuo.
class AlbumDetailScreen extends StatelessWidget {
  /// Nombre del álbum a mostrar. Se utiliza como llave para filtrar el catálogo.
  final String albumName;

  const AlbumDetailScreen({super.key, required this.albumName});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    
    final albumTracks = repo.groupedByAlbum[albumName] ?? [];
    final firstTrack = albumTracks.isNotEmpty ? albumTracks.first : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.grey[900],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(albumName, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: firstTrack != null
                  ? Image.network(
                      firstTrack.coverUrl, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[850],
                          child: const Icon(Icons.wifi_off, color: Colors.white54, size: 80),
                        );
                      },
                    )
                  : const Icon(Icons.album, size: 100, color: Colors.white54),
            ),
          ),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = albumTracks[index];
                final isPlaying = repo.currentTrack?.id == track.id;

                return ListTile(
                  leading: Text('${index + 1}', style: const TextStyle(color: Colors.white54)),
                  title: Text(
                    track.title,
                    style: TextStyle(
                      color: isPlaying ? Colors.redAccent : Colors.white,
                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(track.artist, style: const TextStyle(color: Colors.white54)),
                  onTap: () => repo.playTrackContext(track, albumTracks),
                );
              },
              childCount: albumTracks.length,
            ),
          ),
        ],
      ),
    );
  }
}