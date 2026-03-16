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
          IconButton(
            icon: const Icon(Icons.add), 
            onPressed: () => context.go('/library/create')
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: repo.userPlaylists.length,
        itemBuilder: (context, index) {
          final playlist = repo.userPlaylists[index];
          
          return ListTile(
            // AQUÍ INTEGRAMOS EL CONTENEDOR DE LA IMAGEN
            leading: Container(
              width: 55, // Un poco más pequeño para que encaje perfecto en la lista
              height: 55,
              decoration: BoxDecoration(
                color: Colors.grey[900], 
                borderRadius: BorderRadius.circular(4), 
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                ],
                image: playlist.coverUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(playlist.coverUrl), 
                        fit: BoxFit.cover, 
                      )
                    : null, 
              ),
              child: playlist.coverUrl.isEmpty
                  ? const Icon(Icons.queue_music, color: Colors.white54, size: 28)
                  : null,
            ),
            title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Playlist • ${repo.currentUser?.displayName ?? 'Usuario'}'),
            onTap: () => context.go('/library/playlist/${playlist.id}'),
          );
        },
      ),
    );
  }
}