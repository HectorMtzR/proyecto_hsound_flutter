import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mock/mock_repository.dart';
import '../../features/player/full_player_screen.dart'; // <-- IMPORTANTE IMPORTAR ESTO

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    if (repo.currentTrack == null) return const SizedBox.shrink();

    final track = repo.currentTrack!;
    return GestureDetector(
      // NUEVO: Abrir reproductor en pantalla completa al tocar
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // Permite que use toda la pantalla
          useSafeArea: true,
          builder: (context) => const FullPlayerScreen(),
        );
      },
      child: Container(
        height: 64,
        color: Colors.grey[900],
        child: Row(
          children: [
            Image.network(track.coverUrl, width: 64, height: 64, fit: BoxFit.cover),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1),
                  Text(track.artist, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1),
                ],
              ),
            ),
            IconButton(
              icon: Icon(repo.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
              onPressed: repo.togglePlay,
            ),
          ],
        ),
      ),
    );
  }
}