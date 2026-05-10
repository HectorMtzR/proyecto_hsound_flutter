import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mock/mock_repository.dart';
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
    
    // Si no hay ninguna pista seleccionada, el reproductor simplemente se oculta.
    if (repo.currentTrack == null) return const SizedBox.shrink();

    final track = repo.currentTrack!;
    
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, 
          useSafeArea: true,
          builder: (context) => const FullPlayerScreen(),
        );
      },
      child: Container(
        height: 64,
        color: Colors.grey[900],
        child: Row(
          children: [
            // Imagen con caché en disco y manejo de red (Offline Mode)
            CachedNetworkImage(
              imageUrl: track.coverUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 64,
                height: 64,
                color: Colors.grey[850],
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
                color: Colors.grey[850],
                child: const Icon(Icons.wifi_off, color: Colors.white54, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.title, 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist, 
                    style: const TextStyle(color: Colors.white70, fontSize: 12), 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(repo.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
              onPressed: repo.togglePlay,
            ),
            const SizedBox(width: 8), // Pequeño margen derecho para estética
          ],
        ),
      ),
    );
  }
}