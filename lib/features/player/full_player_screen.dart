import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/mock/mock_repository.dart';
import '../../core/models/models.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    final track = repo.currentTrack;

    if (track == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFC62828), // Fondo Rojo tipo Canva
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Biblioteca de canciones', style: TextStyle(fontSize: 14, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () => _showOptionsSheet(context, repo, track),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Carátula cuadrada grande
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(track.coverUrl, fit: BoxFit.cover),
            ),
            const SizedBox(height: 32),
            
            // Título, Artista y Botón de Me Gusta
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(track.artist, style: const TextStyle(fontSize: 16, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    repo.isLiked(track) ? Icons.favorite : Icons.favorite_border,
                    color: repo.isLiked(track) ? Colors.black : Colors.white,
                    size: 32,
                  ),
                  onPressed: () => repo.toggleLike(track),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Barra de progreso interactiva
            StreamBuilder<Duration>(
              stream: repo.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = repo.currentDuration;
                final maxVal = duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0;
                final currentVal = position.inSeconds.toDouble().clamp(0.0, maxVal);

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        trackHeight: 4.0,
                      ),
                      child: Slider(
                        value: currentVal,
                        max: maxVal,
                        onChanged: (val) => repo.seek(Duration(seconds: val.toInt())),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Controles de reproducción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.shuffle, color: repo.isShuffle ? Colors.black : Colors.white),
                  onPressed: repo.toggleShuffle,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white),
                  onPressed: repo.playPrevious,
                ),
                Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                  child: IconButton(
                    iconSize: 48,
                    icon: Icon(repo.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    onPressed: repo.togglePlay,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
                  onPressed: repo.playNext,
                ),
                IconButton(
                  icon: const Icon(Icons.repeat, color: Colors.white), // Visual por ahora
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM SHEET DE OPCIONES ---
  void _showOptionsSheet(BuildContext context, MockRepository repo, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(margin: const EdgeInsets.only(top: 8, bottom: 16), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
              
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.redAccent),
                title: const Text('Agregar a playlist', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPlaylistSelector(context, repo, track);
                },
              ),

              // SOLO SE MUESTRA SI ESTAMOS ESCUCHANDO DESDE UNA PLAYLIST
              if (repo.currentPlaylistContextId != null)
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  title: const Text('Eliminar de esta playlist', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    repo.removeTrackFromPlaylist(repo.currentPlaylistContextId!, track);
                    Navigator.pop(ctx);
                  },
                ),

              ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.redAccent),
                title: const Text('Agregar a la fila de reproducción', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  repo.addToQueueNext(track);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregada a la fila')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // DIÁLOGO SECUNDARIO PARA SELECCIONAR A QUÉ PLAYLIST AGREGAR
  void _showPlaylistSelector(BuildContext context, MockRepository repo, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      builder: (ctx) {
        return ListView(
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Text('Selecciona una playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ...repo.userPlaylists.map((playlist) => ListTile(
              title: Text(playlist.name),
              onTap: () {
                repo.addTrackToPlaylist(playlist.id, track);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agregada a ${playlist.name}')));
              },
            )),
          ],
        );
      },
    );
  }
}