import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/main/main_layout.dart';
import '../../features/home/home_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/library/create_playlist_screen.dart';
import '../../features/library/playlist_detail_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/info_screen.dart';
import '../mock/mock_repository.dart';

GoRouter createRouter(MockRepository repo) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = repo.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
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
            ],
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/info', builder: (context, state) => const InfoScreen()),
    ],
  );
}