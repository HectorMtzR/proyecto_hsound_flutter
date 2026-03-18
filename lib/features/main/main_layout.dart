import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/mini_player.dart';

/// Diseño estructural (Layout) principal de la aplicación.
///
/// Se utiliza como contenedor base en el enrutador (mediante ShellRoute).
/// Su función principal es mantener persistentes el reproductor minimizado 
/// ([MiniPlayer]) y la barra de navegación inferior ([BottomNavigationBar]) 
/// mientras el usuario navega dinámicamente entre las pantallas principales.
class MainLayout extends StatelessWidget {
  /// El widget hijo que representa la pantalla actual activa en la navegación.
  final Widget child;
  
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayer(), 
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        backgroundColor: Colors.grey[900],
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/search');
          if (index == 2) context.go('/library');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Biblioteca'),
        ],
      ),
    );
  }

  /// Calcula el índice activo de la barra de navegación basado en la ruta actual en pantalla.
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/library')) return 2;
    
    return 0; // Por defecto retorna a Inicio (0)
  }
}