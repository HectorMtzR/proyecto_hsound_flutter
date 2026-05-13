import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/regional_playlist.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/greca_divider.dart';

/// Sección "Música Regional" que aparece debajo del grid principal en Inicio.
///
/// Se oculta automáticamente cuando no hay playlists regionales en el
/// catálogo, así que es seguro colocarla siempre en el árbol.
class RegionalSection extends StatelessWidget {
  final List<RegionalPlaylist> playlists;

  const RegionalSection({super.key, required this.playlists});

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            0,
          ),
          child: Text('Música Regional', style: textTheme.titleMedium),
        ),
        const GrecaDivider(
          size: GrecaSize.micro,
          opacity: 0.5,
          tint: AppColors.brandOrange,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: playlists.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) =>
                _RegionalCard(playlist: playlists[index]),
          ),
        ),
      ],
    );
  }
}

class _RegionalCard extends StatelessWidget {
  final RegionalPlaylist playlist;

  const _RegionalCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final coverUrl = playlist.coverUrl ??
        (playlist.tracks.isNotEmpty ? playlist.tracks.first.coverUrl : '');

    return GestureDetector(
      onTap: () => context.push('/library/playlist/${playlist.id}'),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
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
                child: coverUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        width: 140,
                        height: 140,
                        placeholder: (context, url) => Container(
                          color: AppColors.surfaceContainerHigh,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceContainerHigh,
                          child: const Icon(
                            Icons.wifi_off,
                            color: AppColors.outline,
                            size: 32,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(
                          Icons.music_note,
                          color: AppColors.outline,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              playlist.name,
              style: textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
