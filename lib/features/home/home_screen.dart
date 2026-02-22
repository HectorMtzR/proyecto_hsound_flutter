import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de canciones'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/settings')),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemCount: repo.allTracks.length,
        itemBuilder: (context, index) {
          final track = repo.allTracks[index];
          return GestureDetector(
            onTap: () => repo.playTrack(track),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Image.network(track.coverUrl, fit: BoxFit.cover, width: double.infinity)),
                const SizedBox(height: 8),
                Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                Text(track.artist, style: const TextStyle(color: Colors.white54), maxLines: 1),
              ],
            ),
          );
        },
      ),
    );
  }
}