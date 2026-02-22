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

class HSoundApp extends StatelessWidget {
  const HSoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MockRepository>();
    final router = createRouter(repo);

    return MaterialApp.router(
      title: 'HSound',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}