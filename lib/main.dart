import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- Nuevo import
import 'firebase_options.dart'; // <-- El archivo generado por FlutterFire

import 'core/theme/app_theme.dart';
import 'core/mock/mock_repository.dart';
import 'core/router/app_router.dart';

// Cambiamos el main a "async" para poder esperar a que Firebase cargue
void main() async {
  // Aseguramos que los "bindings" de Flutter estén listos antes de llamar a código nativo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Firebase con las opciones generadas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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