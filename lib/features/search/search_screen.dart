import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';

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
    
    // 1. Lógica del Filtro de Búsqueda
    final filteredTracks = repo.allTracks.where((track) {
      final titleLower = track.title.toLowerCase();
      final artistLower = track.artist.toLowerCase();
      final searchLower = _searchQuery.toLowerCase();
      
      return titleLower.contains(searchLower) || artistLower.contains(searchLower);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        // 2. Campo de texto integrado en el AppBar
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: '¿Qué quieres escuchar?',
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Colors.white54),
            // Botón con la "X" para limpiar la búsqueda rápido
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
            // Cada vez que se teclea una letra, reconstruimos la lista
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
      // 3. Resultados dinámicos
      body: _searchQuery.isEmpty
          ? const Center(
              child: Text('Encuentra tu música favorita', style: TextStyle(color: Colors.white54, fontSize: 16)),
            )
          : filteredTracks.isEmpty
              ? Center(
                  child: Text('No hay resultados para "$_searchQuery"', style: const TextStyle(color: Colors.white54)),
                )
              : ListView.builder(
                  itemCount: filteredTracks.length,
                  itemBuilder: (context, index) {
                    final track = filteredTracks[index];
                    final isPlaying = repo.currentTrack?.id == track.id;

                    return ListTile(
                      leading: Image.network(track.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
                      title: Text(
                        track.title, 
                        style: TextStyle(color: isPlaying ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold)
                      ),
                      subtitle: Text(track.artist, style: const TextStyle(color: Colors.white54)),
                      // Al tocar, armamos una cola solo con los resultados de la búsqueda
                      onTap: () => repo.playTrackContext(track, filteredTracks),
                    );
                  },
                ),
    );
  }
}