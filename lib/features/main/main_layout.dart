import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/mini_player.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayer(), // Siempre visible si hay track
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        // Agregamos un color para que resalte qué pestaña está activa
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        backgroundColor: Colors.grey[900],
        onTap: (index) {
          if (index == 0) context.go('/home');
          // --- NUEVA RUTA DE BÚSQUEDA ---
          if (index == 1) context.go('/search');
          if (index == 2) context.go('/library');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // --- NUEVO ÍCONO AL CENTRO ---
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Biblioteca'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    // Validamos la ruta de búsqueda en el índice 1
    if (location.startsWith('/search')) return 1;
    // La biblioteca pasa al índice 2
    if (location.startsWith('/library')) return 2;
    return 0; // Por defecto Home (0)
  }
}