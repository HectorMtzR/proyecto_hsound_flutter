import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/recognition_result.dart';
import '../theme/app_theme.dart';

class DiscoveryCard extends StatelessWidget {
  const DiscoveryCard({super.key, required this.result});

  final RecognitionResult result;

  static const _spotifyColor = Color(0xFF1DB954);
  static const _appleMusicColor = Color(0xFFFC3C44);

  Future<void> _open() async {
    final Uri? uri;
    if (result.spotifyId != null) {
      uri = Uri.parse(
          'https://open.spotify.com/track/${result.spotifyId}');
    } else if (result.appleMusicId != null) {
      uri = Uri.parse(
          'https://music.apple.com/song/${result.appleMusicId}');
    } else {
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // vitrina pasiva — ignorar silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasLink =
        result.spotifyId != null || result.appleMusicId != null;

    return SizedBox(
      width: 140,
      height: 200,
      child: Material(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: hasLink ? _open : null,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                  color: AppColors.outlineVariant, width: 1),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CoverImage(coverUrl: result.coverUrl),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xs,
                          AppSpacing.xs,
                          AppSpacing.xs,
                          AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _UnavailableBadge(textTheme: textTheme),
                          const SizedBox(height: 3),
                          Text(
                            result.title,
                            style: textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            result.artist,
                            style: textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          if (hasLink)
                            Align(
                              alignment: Alignment.centerRight,
                              child: _PlatformBadge(
                                useSpotify: result.spotifyId != null,
                                textTheme: textTheme,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final url = coverUrl;
    if (url == null || url.isEmpty) {
      return Container(
        height: 110,
        color: AppColors.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.music_note,
              color: AppColors.outline, size: 36),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: 110,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        height: 110,
        color: AppColors.surfaceContainerHighest,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, _, _) => Container(
        height: 110,
        color: AppColors.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.music_note,
              color: AppColors.outline, size: 36),
        ),
      ),
    );
  }
}

class _UnavailableBadge extends StatelessWidget {
  const _UnavailableBadge({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        'No disponible en HSound',
        style: textTheme.labelSmall
            ?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 9),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge(
      {required this.useSpotify, required this.textTheme});

  final bool useSpotify;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: useSpotify
                ? DiscoveryCard._spotifyColor
                : DiscoveryCard._appleMusicColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          useSpotify ? 'Spotify' : 'Apple Music',
          style: textTheme.labelSmall
              ?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 9),
        ),
      ],
    );
  }
}
