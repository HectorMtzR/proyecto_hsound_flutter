import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mock/mock_repository.dart';
import '../theme/app_theme.dart';
import '../../features/player/full_player_screen.dart';

/// Reproductor minimizado (MiniPlayer) persistente.
///
/// Se muestra encima de la barra de navegación inferior en las pantallas principales.
/// Muestra la pista actual, permite pausar/reproducir rápidamente y, al ser presionado,
/// despliega el reproductor a pantalla completa ([FullPlayerScreen]).
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();

    if (repo.currentTrack == null) return const SizedBox.shrink();

    final track = repo.currentTrack!;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const FullPlayerScreen(),
        );
      },
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadii.sm),
                bottomLeft: Radius.circular(AppRadii.sm),
              ),
              child: CachedNetworkImage(
                imageUrl: track.coverUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 64,
                  height: 64,
                  color: AppColors.surfaceContainerHigh,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 64,
                  height: 64,
                  color: AppColors.surfaceContainerHigh,
                  child: const Icon(Icons.wifi_off, color: AppColors.outline, size: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          track.title,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (repo.isDownloaded(track)) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.download_done, size: 14, color: AppColors.brandTurquoise),
                      ],
                    ],
                  ),
                  Text(
                    track.artist,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                repo.isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.brandOrange,
                size: 28,
              ),
              onPressed: repo.togglePlay,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
