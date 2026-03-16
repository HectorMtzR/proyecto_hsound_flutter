import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart'; // <-- 1. IMPORT FALTANTE

import 'core/theme/app_theme.dart';
import 'core/mock/mock_repository.dart';
import 'core/router/app_router.dart';

void main() async {
  // Aseguramos que los "bindings" de Flutter estén listos antes de llamar a código nativo
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Cargamos variables de entorno
  await dotenv.load(fileName: ".env");

  // 2. INICIALIZAMOS EL AUDIO EN BACKGROUND (ESTO FALTABA)
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Reproducción de música',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher', // Usa el ícono de tu app
  );

  // 3. Inicializamos Firebase (una sola vez)
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