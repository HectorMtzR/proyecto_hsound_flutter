import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';

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
    
    // Filtro interactivo insensible a mayúsculas/minúsculas
    final filteredTracks = repo.allTracks.where((track) {
      final titleLower = track.title.toLowerCase();
      final artistLower = track.artist.toLowerCase();
      final searchLower = _searchQuery.toLowerCase();
      
      return titleLower.contains(searchLower) || artistLower.contains(searchLower);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: '¿Qué quieres escuchar?',
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Colors.white54),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
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
      ),
      body: _searchQuery.isEmpty
          ? const Center(
              child: Text(
                'Encuentra tu música favorita', 
                style: TextStyle(color: Colors.white54, fontSize: 16)
              ),
            )
          : filteredTracks.isEmpty
              ? Center(
                  child: Text(
                    'No hay resultados para "$_searchQuery"', 
                    style: const TextStyle(color: Colors.white54)
                  ),
                )
              : ListView.builder(
                  itemCount: filteredTracks.length,
                  itemBuilder: (context, index) {
                    final track = filteredTracks[index];
                    final isPlaying = repo.currentTrack?.id == track.id;

                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[850],
                        child: Image.network(
                          track.coverUrl, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.wifi_off, color: Colors.white54, size: 24);
                          },
                        ),
                      ),
                      title: Text(
                        track.title, 
                        style: TextStyle(
                          color: isPlaying ? Colors.redAccent : Colors.white, 
                          fontWeight: FontWeight.bold
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artist, 
                        style: const TextStyle(color: Colors.white54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => repo.playTrackContext(track, filteredTracks),
                    );
                  },
                ),
    );
  }
}