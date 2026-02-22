import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    final playlist = repo.userPlaylists.firstWhere((p) => p.id == playlistId);

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/library'))),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(width: 150, height: 150, color: Colors.grey[800], child: const Icon(Icons.album, size: 80, color: Colors.white24)),
                const SizedBox(height: 16),
                Text(playlist.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: playlist.tracks.length,
              itemBuilder: (context, index) {
                final track = playlist.tracks[index];
                return ListTile(
                  leading: Image.network(track.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
                  title: Text(track.title),
                  subtitle: Text(track.artist),
                  trailing: const Icon(Icons.more_vert),
                  onTap: () => repo.playTrack(track),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}