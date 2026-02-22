import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/mock/mock_repository.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MockRepository(),
      child: const HSoundApp(),
    ),
  );
}

class HSoundApp extends StatefulWidget {
  const HSoundApp({super.key});

  @override
  State<HSoundApp> createState() => _HSoundAppState();
}

class _HSoundAppState extends State<HSoundApp> {
  late final router;

  @override
  void initState() {
    super.initState();
    // Leemos el repositorio UNA SOLA VEZ al arrancar
    final repo = context.read<MockRepository>();
    router = createRouter(repo);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HSound',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}