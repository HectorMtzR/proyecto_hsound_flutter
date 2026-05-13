import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/greca_divider.dart';

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
    final textTheme = Theme.of(context).textTheme;

    final playlistIndex = repo.userPlaylists.indexWhere((p) => p.id == playlistId);
    Playlist? resolved;
    if (playlistIndex != -1) {
      resolved = repo.userPlaylists[playlistIndex];
    } else {
      for (final regional in repo.regionalPlaylists) {
        if (regional.id == playlistId) {
          resolved = regional.toPlaylist();
          break;
        }
      }
    }

    if (resolved == null) {
      return Scaffold(
        body: Center(
          child: Text('Playlist no encontrada o eliminada', style: textTheme.bodyMedium),
        ),
      );
    }
    final playlist = resolved;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/library'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowTinted.withValues(alpha: 0.6),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: playlist.coverUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            child: CachedNetworkImage(
                              imageUrl: playlist.coverUrl,
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Icon(Icons.wifi_off, color: AppColors.outline, size: 80),
                              ),
                            ),
                          )
                        : const Icon(Icons.music_note, color: AppColors.outline, size: 80),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  playlist.name,
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${playlist.tracks.length} canciones',
                  style: textTheme.labelSmall,
                ),
                const SizedBox(height: AppSpacing.md),

                ElevatedButton.icon(
                  icon: const Icon(Icons.shuffle, size: 22),
                  label: const Text('REPRODUCCIÓN ALEATORIA'),
                  onPressed: () {
                    if (playlist.tracks.isNotEmpty) {
                      if (!repo.isShuffle) repo.toggleShuffle();

                      final randomIndex = Random().nextInt(playlist.tracks.length);
                      final randomStartingTrack = playlist.tracks[randomIndex];
                      repo.playTrackContext(randomStartingTrack, playlist.tracks, playlistId: playlist.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Esta playlist no tiene canciones aún.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const GrecaDivider(
            size: GrecaSize.small,
            opacity: 0.5,
            tint: AppColors.brandOrange,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: playlist.tracks.length,
              itemBuilder: (context, index) {
                final track = playlist.tracks[index];
                final isPlaying = repo.currentTrack?.id == track.id;

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: track.coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: track.coverUrl,
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Icon(Icons.wifi_off, color: AppColors.outline, size: 24),
                              ),
                            )
                          : Container(
                              color: AppColors.surfaceContainerHigh,
                              child: const Icon(Icons.music_note, color: AppColors.outline),
                            ),
                    ),
                  ),
                  title: Text(
                    track.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: isPlaying ? AppColors.brandOrange : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist,
                    style: textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DownloadButton(track: track),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
                        onPressed: () => _showOptionsSheet(context, repo, track, playlist.id),
                      ),
                    ],
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

  void _showOptionsSheet(BuildContext context, MockRepository repo, Track track, String currentPlaylistId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppColors.brandOrange),
                title: Text('Agregar a otra playlist', style: Theme.of(ctx).textTheme.titleSmall),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPlaylistSelector(context, repo, track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                title: Text(
                  'Eliminar de esta playlist',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(color: AppColors.error),
                ),
                onTap: () {
                  repo.removeTrackFromPlaylist(currentPlaylistId, track);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music, color: AppColors.brandTurquoise),
                title: Text('Agregar a la fila de reproducción', style: Theme.of(ctx).textTheme.titleSmall),
                onTap: () {
                  repo.addToQueueNext(track);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agregada a la fila')),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylistSelector(BuildContext context, MockRepository repo, Track track) {
    final userCreatedPlaylists = repo.userPlaylists.where(
      (p) => p.id != 'p_likes' && p.id != 'p_1',
    ).toList();

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Selecciona una playlist', style: Theme.of(ctx).textTheme.titleLarge),
              ),
              if (userCreatedPlaylists.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'No has creado ninguna playlist personal aún.',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ...userCreatedPlaylists.map((playlist) => ListTile(
                    title: Text(playlist.name, style: Theme.of(ctx).textTheme.titleSmall),
                    onTap: () {
                      repo.addTrackToPlaylist(playlist.id, track);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Agregada a ${playlist.name}')),
                      );
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}

/// Botón de descarga local de la pista. Cambia entre tres estados:
/// pendiente, en progreso (spinner) y descargada (palomita).
class _DownloadButton extends StatefulWidget {
  final Track track;
  const _DownloadButton({required this.track});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _busy = false;

  Future<void> _toggle(MockRepository repo) async {
    if (_busy) return;
    final wasDownloaded = repo.isDownloaded(widget.track);

    if (wasDownloaded) {
      await repo.removeDownload(widget.track);
      return;
    }

    setState(() => _busy = true);
    try {
      await repo.downloadTrack(widget.track);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    final isDownloaded = repo.isDownloaded(widget.track);

    if (_busy) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      tooltip: isDownloaded ? 'Quitar descarga' : 'Descargar al dispositivo',
      icon: Icon(
        isDownloaded ? Icons.download_done : Icons.download_for_offline_outlined,
        color: isDownloaded ? AppColors.brandTurquoise : AppColors.onSurfaceVariant,
      ),
      onPressed: () => _toggle(repo),
    );
  }
}
