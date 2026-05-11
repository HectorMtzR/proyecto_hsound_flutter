import 'package:go_router/go_router.dart';

import '../models/recognition_result.dart';
import '../mock/mock_repository.dart';
import '../../features/auth/login_screen.dart';
import '../../features/main/main_layout.dart';
import '../../features/home/home_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/library/create_playlist_screen.dart';
import '../../features/library/playlist_detail_screen.dart';
import '../../features/library/album_detail_screen.dart';
import '../../features/recognize/recognize_screen.dart';
import '../../features/recognize/recognition_result_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/info_screen.dart';

/// Configura y genera el enrutador principal de la aplicación.
///
/// Utiliza [GoRouter] para el manejo de rutas declarativas.
/// Implementa un "Guard" de autenticación que redirige automáticamente
/// al usuario a la pantalla de inicio de sesión si no está autenticado,
/// o a la pantalla principal si ya lo está.
/// 
/// También configura un [ShellRoute] para mantener persistente el
/// reproductor minimizado y la barra de navegación inferior en las 
/// pantallas principales.
GoRouter createRouter(MockRepository repo) {
  return GoRouter(
    initialLocation: '/home',
    // El router reacciona a los cambios en el MockRepository (ej. Login/Logout)
    refreshListenable: repo, 
    
    // --- GUARD DE AUTENTICACIÓN ---
    redirect: (context, state) {
      final isLoggedIn = repo.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login';
      
      // Si no está logueado y no está en la pantalla de login, lo mandamos al login
      if (!isLoggedIn && !isLoggingIn) return '/login';
      
      // Si ya está logueado pero intenta ir al login, lo mandamos al home
      if (isLoggedIn && isLoggingIn) return '/home';
      
      // En cualquier otro caso, permitimos la navegación normal
      return null; 
    },
    
    // --- ÁRBOL DE RUTAS ---
    routes: [
      GoRoute(
        path: '/login', 
        builder: (context, state) => const LoginScreen(),
      ),
      
      // ShellRoute envuelve las rutas hijas con el MainLayout (BottomNav + MiniPlayer)
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/home', 
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search', 
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/library',
            builder: (context, state) => const LibraryScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreatePlaylistScreen(),
              ),
              GoRoute(
                path: 'playlist/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaylistDetailScreen(playlistId: id);
                },
              ),
              GoRoute(
                path: 'album/:name',
                builder: (context, state) {
                  final name = state.pathParameters['name']!;
                  return AlbumDetailScreen(albumName: name);
                },
              ),
            ],
          ),
        ],
      ),
      
      // Rutas fuera del Shell (Pantallas que ocultan la barra inferior de navegación)
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/info',
        builder: (context, state) => const InfoScreen(),
      ),
      GoRoute(
        path: '/recognize',
        builder: (context, state) => const RecognizeScreen(),
        routes: [
          GoRoute(
            path: 'result',
            builder: (context, state) => RecognitionResultScreen(
              result: state.extra as RecognitionResult,
            ),
          ),
        ],
      ),
    ],
  );
}