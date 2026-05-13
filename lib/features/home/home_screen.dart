import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/models/recognition_result.dart';
import '../../core/services/discovery_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/discovery_card.dart';
import '../../core/widgets/greca_divider.dart';
import 'widgets/regional_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _discoveryService = DiscoveryService();
  Future<List<RecognitionResult>>? _discoveryFuture;
  bool _discoveryInitialized = false;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();

    // Inicializar una sola vez, pero sólo cuando ya tengamos tracks con género.
    // allTracks arranca vacío y se rellena asincrónicamente desde Firestore/Hive;
    // si iniciamos antes no hay géneros que pasar a AudD.
    if (!_discoveryInitialized) {
      final genres = repo.allTracks
          .map((t) => t.genre)
          .whereType<String>()
          .toSet()
          .toList();
      if (genres.isNotEmpty) {
        _discoveryInitialized = true;
        _discoveryFuture =
            _discoveryService.fetchRelatedTracks(genres, repo.allTracks);
      }
    }
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.onSurfaceVariant),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: GrecaDivider(
              size: GrecaSize.small,
              opacity: 0.6,
              tint: AppColors.brandOrange,
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = repo.allTracks[index];
                  final isPlaying = repo.currentTrack?.id == track.id;

                  return GestureDetector(
                    onTap: () =>
                        repo.playTrackContext(track, repo.allTracks),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Hero(
                            tag: 'track_cover_${track.id}',
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                border: isPlaying
                                    ? Border.all(
                                        color: AppColors.brandOrange,
                                        width: 2)
                                    : Border.all(
                                        color: AppColors.outlineVariant,
                                        width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowTinted
                                        .withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                child: CachedNetworkImage(
                                  imageUrl: track.coverUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.surfaceContainerHigh,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: AppColors.surfaceContainerHigh,
                                    child: const Icon(Icons.wifi_off,
                                        color: AppColors.outline, size: 40),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          track.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: isPlaying
                                ? AppColors.brandOrange
                                : AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          track.artist,
                          style: textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
                childCount: repo.allTracks.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: RegionalSection(playlists: repo.regionalPlaylists),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<RecognitionResult>>(
              future: _discoveryFuture,
              builder: (context, snapshot) {
                // Aún no hay future (esperando que carguen los tracks con género)
                if (_discoveryFuture == null) {
                  return const SizedBox.shrink();
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final tracks = snapshot.data ?? [];
                if (tracks.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                          AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                      child: Text('Descubre más',
                          style: textTheme.titleMedium),
                    ),
                    const GrecaDivider(
                      size: GrecaSize.small,
                      opacity: 0.5,
                      tint: AppColors.brandOrange,
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    ),
                    SizedBox(
                      height: 216,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        itemCount: tracks.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, i) =>
                            DiscoveryCard(result: tracks[i]),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}
