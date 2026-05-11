import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/theme/app_theme.dart';

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
    final textTheme = Theme.of(context).textTheme;

    final albumTracks = repo.groupedByAlbum[albumName] ?? [];
    final firstTrack = albumTracks.isNotEmpty ? albumTracks.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                albumName,
                style: GoogleFonts.almendra(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (firstTrack != null)
                    CachedNetworkImage(
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
                        child: const Icon(Icons.wifi_off, color: AppColors.outline, size: 80),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surfaceContainerHigh,
                      child: const Icon(Icons.album, size: 100, color: AppColors.outline),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.95),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = albumTracks[index];
                final isPlaying = repo.currentTrack?.id == track.id;

                return ListTile(
                  leading: SizedBox(
                    width: 28,
                    child: Text(
                      '${index + 1}',
                      style: textTheme.labelLarge?.copyWith(color: AppColors.outline),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  title: Text(
                    track.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: isPlaying ? AppColors.brandOrange : AppColors.onSurface,
                    ),
                  ),
                  subtitle: Text(track.artist, style: textTheme.labelSmall),
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
