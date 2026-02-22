import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Biblioteca'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/library/create')),
        ],
      ),
      body: ListView.builder(
        itemCount: repo.userPlaylists.length,
        itemBuilder: (context, index) {
          final playlist = repo.userPlaylists[index];
          return ListTile(
            leading: Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.music_note)),
            title: Text(playlist.name),
            subtitle: Text('Playlist • ${repo.currentUser?.displayName}'),
            onTap: () => context.go('/library/playlist/${playlist.id}'),
          );
        },
      ),
    );
  }
}