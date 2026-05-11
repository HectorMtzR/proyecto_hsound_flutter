import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla de reproducción a pantalla completa.
///
/// Muestra la carátula de la canción actual con una animación [Hero],
/// controles de reproducción, barra de progreso y extrae dinámicamente
/// el color de fondo basado en la paleta de colores de la imagen.
class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  /// Color de fondo dinámico. Se inicializa con el primario de la marca.
  Color _backgroundColor = AppColors.brandOrangeDeep;

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  @override
  void didUpdateWidget(covariant FullPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePalette();
  }

  /// Extrae el color dominante de la URL de la portada de la canción actual.
  Future<void> _updatePalette() async {
    final repo = context.read<MockRepository>();
    final track = repo.currentTrack;

    if (track == null || track.coverUrl.isEmpty) return;

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(track.coverUrl),
        maximumColorCount: 10,
      );

      if (mounted) {
        setState(() {
          _backgroundColor = palette.darkVibrantColor?.color ??
              palette.dominantColor?.color ??
              AppColors.brandOrangeDeep;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conexión inestable. No se pudo cargar la portada de la pista.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Formatea un objeto [Duration] a una cadena (mm:ss) para la UI.
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    final track = repo.currentTrack;
    final textTheme = Theme.of(context).textTheme;

    if (track == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(_backgroundColor, AppColors.background, 0.25) ?? _backgroundColor,
              AppColors.background,
            ],
            stops: const [0.0, 0.85],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 32, color: AppColors.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Reproduciendo',
                  style: textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppColors.onSurface),
                    onPressed: () => _showOptionsSheet(context, repo, track),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'track_cover_${track.id}',
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowTinted.withValues(alpha: 0.6),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              child: CachedNetworkImage(
                                imageUrl: track.coverUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.surfaceContainerHigh,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surfaceContainerHigh,
                                  child: const Icon(Icons.wifi_off, color: AppColors.outline, size: 40),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        track.title,
                                        style: textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (repo.isDownloaded(track)) ...[
                                      const SizedBox(width: AppSpacing.sm),
                                      const Icon(Icons.download_done, size: 18, color: AppColors.brandTurquoise),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  track.artist,
                                  style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              repo.isLiked(track) ? Icons.favorite : Icons.favorite_border,
                              color: repo.isLiked(track) ? AppColors.brandOrange : AppColors.onSurface,
                              size: 32,
                            ),
                            onPressed: () => repo.toggleLike(track),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      StreamBuilder<Duration>(
                        stream: repo.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = repo.currentDuration;
                          final maxVal = duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0;
                          final currentVal = position.inSeconds.toDouble().clamp(0.0, maxVal);

                          return Column(
                            children: [
                              Slider(
                                value: currentVal,
                                max: maxVal,
                                onChanged: (val) => repo.seek(Duration(seconds: val.toInt())),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(position),
                                        style: textTheme.labelSmall),
                                    Text(_formatDuration(duration),
                                        style: textTheme.labelSmall),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(Icons.shuffle,
                                color: repo.isShuffle ? AppColors.brandTurquoise : AppColors.onSurfaceVariant),
                            onPressed: repo.toggleShuffle,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 40, color: AppColors.onSurface),
                            onPressed: repo.playPrevious,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.brandOrangeDeep,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandOrange.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IconButton(
                              iconSize: 48,
                              icon: Icon(
                                repo.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: AppColors.onPrimary,
                              ),
                              onPressed: repo.togglePlay,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 40, color: AppColors.onSurface),
                            onPressed: repo.playNext,
                          ),
                          IconButton(
                            icon: const Icon(Icons.repeat, color: AppColors.onSurfaceVariant),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra un menú de opciones contextual para la pista actual.
  void _showOptionsSheet(BuildContext context, MockRepository repo, Track track) {
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
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppColors.brandOrange),
                title: Text('Agregar a playlist',
                    style: Theme.of(ctx).textTheme.titleSmall),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPlaylistSelector(context, repo, track);
                },
              ),
              if (repo.currentPlaylistContextId != null)
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                  title: Text('Eliminar de esta playlist',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(color: AppColors.error)),
                  onTap: () {
                    repo.removeTrackFromPlaylist(repo.currentPlaylistContextId!, track);
                    Navigator.pop(ctx);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.queue_music, color: AppColors.brandTurquoise),
                title: Text('Agregar a la fila de reproducción',
                    style: Theme.of(ctx).textTheme.titleSmall),
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

  /// Muestra un selector para añadir la pista a una de las playlists del usuario.
  void _showPlaylistSelector(BuildContext context, MockRepository repo, Track track) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Selecciona una playlist',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              ...repo.userPlaylists.map((playlist) => ListTile(
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
