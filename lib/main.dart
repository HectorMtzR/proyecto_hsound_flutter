import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Necesario para bloquear la orientación
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/data/local_db.dart';
import 'core/theme/app_theme.dart';
import 'core/mock/mock_repository.dart';
import 'core/router/app_router.dart';
import 'core/services/audio_capture_service.dart';
import 'core/services/recognition/audd_recognition_service.dart';
import 'core/services/recognition/recognition_service.dart';

/// Llave global del [ScaffoldMessenger] para emitir SnackBars desde lugares
/// que no tienen [BuildContext] disponible (p. ej. callbacks de red en el
/// repositorio).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Punto de entrada principal de la aplicación HSound.
///
/// Inicializa los servicios críticos del sistema de forma asíncrona antes
/// de renderizar la interfaz de usuario:
/// - Bloqueo de la orientación de la pantalla a modo retrato (Portrait).
/// - Configuración del servicio en segundo plano para el audio.
/// - Inicialización del SDK de Firebase.
Future<void> main() async {
  // Aseguramos que los "bindings" de Flutter estén listos para código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // Bloqueamos la rotación para evitar reconstrucciones no deseadas de la UI
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicialización de los canales de notificación de Android para reproducción en background
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Reproducción de música',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );

  // Inicialización de la conexión con Firestore y Firebase Auth
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Persistencia local (Hive) — necesaria para el modo offline.
  // Se inicializa después de Firebase para que MockRepository pueda hidratar
  // desde la caché antes del primer evento de Auth.
  await LocalDb.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<AudioCaptureService>(
          create: (_) => AudioCaptureService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<RecognitionService>(
          create: (_) => AuddRecognitionService(),
        ),
        ChangeNotifierProvider(create: (_) => MockRepository()),
      ],
      child: const HSoundApp(),
    ),
  );
}

/// Widget raíz de la aplicación.
///
/// Configura el tema global oscuro y el sistema de enrutamiento dinámico [GoRouter],
/// inyectando el repositorio de datos como dependencia para controlar el acceso
/// según el estado de autenticación del usuario.
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
    // Leemos el repositorio una sola vez al arrancar para pasárselo al enrutador
    final repo = context.read<MockRepository>();
    router = createRouter(repo);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HSound',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
    );
  }
}