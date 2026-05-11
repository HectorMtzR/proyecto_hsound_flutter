import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla interactiva de búsqueda en tiempo real.
///
/// Implementa un campo de texto en el [AppBar] que filtra el catálogo
/// completo de canciones conforme el usuario teclea (búsqueda dinámica).
/// Filtra resultados analizando coincidencias tanto en el título
/// de la canción como en el nombre del artista.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    final textTheme = Theme.of(context).textTheme;

    final filteredTracks = repo.allTracks.where((track) {
      final titleLower = track.title.toLowerCase();
      final artistLower = track.artist.toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      return titleLower.contains(searchLower) || artistLower.contains(searchLower);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: '¿Qué quieres escuchar?',
                prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.onSurfaceVariant),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _searchQuery.isEmpty
                  ? Center(
                      child: Text(
                        'Encuentra tu música favorita',
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    )
                  : filteredTracks.isEmpty
                      ? Center(
                          child: Text(
                            'No hay resultados para "$_searchQuery"',
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredTracks.length,
                          itemBuilder: (context, index) {
                            final track = filteredTracks[index];
                            final isPlaying = repo.currentTrack?.id == track.id;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CachedNetworkImage(
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
                              onTap: () => repo.playTrackContext(track, filteredTracks),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
