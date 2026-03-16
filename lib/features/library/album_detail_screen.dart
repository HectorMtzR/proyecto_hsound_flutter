import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/models/models.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;

  const AlbumDetailScreen({super.key, required this.albumName});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    // Filtramos las canciones que pertenecen a este álbum
    final albumTracks = repo.groupedByAlbum[albumName] ?? [];
    final firstTrack = albumTracks.isNotEmpty ? albumTracks.first : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // AppBar con la imagen del álbum que se encoge al hacer scroll
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.grey[900],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(albumName, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: firstTrack != null
                  ? Image.network(firstTrack.coverUrl, fit: BoxFit.cover)
                  : const Icon(Icons.album, size: 100),
            ),
          ),
          
          // Lista de canciones del álbum
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