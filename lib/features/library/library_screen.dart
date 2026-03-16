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
            
            // --- NUEVA FUNCIONALIDAD: DEJAR PRESIONADO ---
            onLongPress: () {
              // Evitamos que intenten borrar las listas por defecto
              if (playlist.id == 'p_likes' || playlist.id == 'p_1') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No puedes eliminar una playlist del sistema.'))
                );
                return;
              }

              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text('Eliminar Playlist', style: TextStyle(color: Colors.white)),
                  content: Text('¿Estás seguro de que deseas eliminar "${playlist.name}"? Esta acción no se puede deshacer.', style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx); // Cerramos el diálogo primero
                        try {
                          await repo.deletePlaylist(playlist.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist eliminada')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
                          }
                        }
                      },
                      child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}