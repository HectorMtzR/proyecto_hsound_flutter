import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/recognition_result.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_logger.dart';
import '../../core/widgets/greca_divider.dart';

/// Pantalla de resultado del reconocimiento (fuente externa, fase 1).
///
/// Muestra la canción identificada por AudD junto con un badge "No está en
/// tu biblioteca" y deep-links opcionales a Spotify y Apple Music.
class RecognitionResultScreen extends StatelessWidget {
  const RecognitionResultScreen({super.key, required this.result});

  final RecognitionResult result;

  static const _tag = 'RecognitionResultScreen';

  Future<void> _open(BuildContext context, Uri uri, String fallbackName) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir $fallbackName.')),
        );
      }
    } catch (e, s) {
      AppLogger.warn('Fallo abriendo $fallbackName', error: e, stack: s, tag: _tag);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir $fallbackName.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final year = result.releaseYear;
    final album = result.album;
    final subtitle = [
      if (album != null && album.isNotEmpty) album,
      ?year,
    ].join(' • ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GrecaDivider(
              size: GrecaSize.small,
              opacity: 0.6,
              tint: AppColors.brandOrange,
              padding: EdgeInsets.only(bottom: AppSpacing.md),
            ),
            Center(child: _Cover(url: result.coverUrl)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              result.title,
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              result.artist,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const _NotInLibraryBadge(),
            const SizedBox(height: AppSpacing.lg),
            _ExternalActions(
              spotifyId: result.spotifyId,
              appleMusicId: result.appleMusicId,
              onOpenSpotify: () => _open(
                context,
                Uri.parse('https://open.spotify.com/track/${result.spotifyId}'),
                'Spotify',
              ),
              onOpenAppleMusic: () => _open(
                context,
                Uri.parse('https://music.apple.com/song/${result.appleMusicId}'),
                'Apple Music',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reconocer otra'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: const Icon(
        Icons.music_note,
        size: 72,
        color: AppColors.onSurfaceVariant,
      ),
    );

    final cover = url;
    if (cover == null || cover.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: CachedNetworkImage(
        imageUrl: cover,
        width: 240,
        height: 240,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}

class _NotInLibraryBadge extends StatelessWidget {
  const _NotInLibraryBadge();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.library_add_outlined,
            size: 18,
            color: AppColors.brandGold,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'No está en tu biblioteca',
              style: textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalActions extends StatelessWidget {
  const _ExternalActions({
    required this.spotifyId,
    required this.appleMusicId,
    required this.onOpenSpotify,
    required this.onOpenAppleMusic,
  });

  final String? spotifyId;
  final String? appleMusicId;
  final VoidCallback onOpenSpotify;
  final VoidCallback onOpenAppleMusic;

  @override
  Widget build(BuildContext context) {
    final hasSpotify = spotifyId != null && spotifyId!.isNotEmpty;
    final hasApple = appleMusicId != null && appleMusicId!.isNotEmpty;

    if (!hasSpotify && !hasApple) {
      return Text(
        'No hay enlaces externos disponibles para esta canción.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (hasSpotify)
          ElevatedButton.icon(
            onPressed: onOpenSpotify,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir en Spotify'),
          ),
        if (hasApple)
          ElevatedButton.icon(
            onPressed: onOpenAppleMusic,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir en Apple Music'),
          ),
      ],
    );
  }
}
