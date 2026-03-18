import 'package:flutter/material.dart';

/// Define la paleta de colores y la configuración visual global de la aplicación.
///
/// Centraliza los estilos de "HSound" para asegurar consistencia en todas 
/// las pantallas. Actualmente implementa un tema oscuro (Dark Mode) con 
/// acentos en rojo, inspirado en las interfaces modernas de streaming.
class AppTheme {
  
  /// Retorna la configuración completa del tema oscuro principal.
  /// 
  /// Utiliza un fondo gris muy oscuro [0xFF121212] como base, 
  /// superficies ligeramente más claras [0xFF1E1E1E] para tarjetas o barras,
  /// y [Colors.redAccent] como color de acento para botones e indicadores activos.
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: Colors.redAccent,
      colorScheme: const ColorScheme.dark(
        primary: Colors.redAccent,
        secondary: Colors.red,
        surface: Color(0xFF1E1E1E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white54,
      ),
    );
  }
}