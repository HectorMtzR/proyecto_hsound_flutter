import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/theme/app_theme.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tu Biblioteca'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.brandOrange),
              onPressed: () => context.push('/library/create'),
            ),
          ],
          bottom: const TabBar(
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Playlists'),
              Tab(text: 'Álbumes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- VISTA 1: TUS PLAYLISTS ---
            ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: repo.userPlaylists.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final playlist = repo.userPlaylists[index];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: playlist.coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: playlist.coverUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Icon(Icons.music_note, color: AppColors.outline),
                              ),
                            )
                          : Container(
                              color: AppColors.surfaceContainerHigh,
                              child: const Icon(Icons.music_note, color: AppColors.outline),
                            ),
                    ),
                  ),
                  title: Text(playlist.name, style: textTheme.titleSmall),
                  subtitle: Text('${playlist.tracks.length} canciones', style: textTheme.labelSmall),
                  onTap: () => context.push('/library/playlist/${playlist.id}'),
                  onLongPress: () {
                    final nameLower = playlist.name.toLowerCase();
                    if (nameLower.contains('me gusta') || nameLower.contains('mix')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No puedes eliminar las playlists del sistema'),
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        title: Text('Eliminar Playlist', style: textTheme.titleLarge),
                        content: Text(
                          '¿Seguro que quieres eliminar "${playlist.name}"?',
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppColors.error),
                            onPressed: () {
                              repo.deletePlaylist(playlist.id);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Playlist eliminada')),
                              );
                            },
                            child: const Text('Eliminar'),
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
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
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
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(color: AppColors.outlineVariant, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowTinted.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            child: CachedNetworkImage(
                              imageUrl: firstTrack.coverUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Center(
                                  child: Icon(Icons.wifi_off, color: AppColors.outline, size: 40),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        albumName,
                        style: textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        firstTrack.artist,
                        style: textTheme.labelSmall,
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
