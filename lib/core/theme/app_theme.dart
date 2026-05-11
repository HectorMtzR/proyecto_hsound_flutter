import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidad visual "Alebrije Night" de HSound.
///
/// Tokens derivados de design/DESIGN.md: paleta cálida nocturna con primario
/// naranja, secundario turquesa y terciario dorado sobre superficies wine-tinted.
/// Tipografía dual Almendra (display/headings) + Montserrat (body/labels).
class AppColors {
  // Brand
  static const brandOrange = Color(0xFFFFB693);
  static const brandOrangeDeep = Color(0xFFEE6812);
  static const brandTurquoise = Color(0xFF4FDBCC);
  static const brandGold = Color(0xFFE4C447);

  // Surfaces
  static const background = Color(0xFF1C110B);
  static const surface = Color(0xFF1C110B);
  static const surfaceContainerLow = Color(0xFF251913);
  static const surfaceContainer = Color(0xFF2A1D17);
  static const surfaceContainerHigh = Color(0xFF352720);
  static const surfaceContainerHighest = Color(0xFF40312B);

  // Text
  static const onSurface = Color(0xFFF6DDD3);
  static const onSurfaceVariant = Color(0xFFE1C0B2);
  static const onPrimary = Color(0xFF561F00);
  static const onSecondary = Color(0xFF003732);
  static const onTertiary = Color(0xFF3B2F00);

  // Bordes / sombras
  static const outline = Color(0xFFA88B7E);
  static const outlineVariant = Color(0xFF594237);
  static const shadowTinted = Color(0xFF0D080A);

  // Estados
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
}

class AppRadii {
  static const sm = 4.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 30.0;
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    final montserratBody = GoogleFonts.montserratTextTheme(base.textTheme).apply(
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.onSurface,
    );

    final textTheme = montserratBody.copyWith(
      // Display & headlines en Almendra (artesanal, calligraphic)
      displayLarge: GoogleFonts.almendra(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 56 / 48,
        letterSpacing: -0.96,
        color: AppColors.onSurface,
      ),
      displayMedium: GoogleFonts.almendra(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      displaySmall: GoogleFonts.almendra(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      headlineLarge: GoogleFonts.almendra(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        color: AppColors.onSurface,
      ),
      headlineMedium: GoogleFonts.almendra(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        color: AppColors.onSurface,
      ),
      headlineSmall: GoogleFonts.almendra(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 32 / 24,
        color: AppColors.onSurface,
      ),
      // Title — Montserrat semibold
      titleLarge: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      // Body
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        color: AppColors.onSurface,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.onSurface,
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
      ),
      // Labels — uppercase tracking estilo textil
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.7,
        color: AppColors.onSurface,
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.onSurface,
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.96,
        color: AppColors.onSurfaceVariant,
      ),
    );

    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.brandOrange,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.brandOrangeDeep,
      onPrimaryContainer: Color(0xFF4B1B00),
      secondary: AppColors.brandTurquoise,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: Color(0xFF00B4A6),
      onSecondaryContainer: Color(0xFF003F39),
      tertiary: AppColors.brandGold,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: Color(0xFFC7A92D),
      onTertiaryContainer: Color(0xFF4C3E00),
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: Color(0xFF170B07),
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      shadow: AppColors.shadowTinted,
      inverseSurface: AppColors.onSurface,
      onInverseSurface: Color(0xFF3C2D27),
      inversePrimary: Color(0xFFA04100),
      surfaceTint: AppColors.brandOrange,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      primaryColor: AppColors.brandOrange,
      canvasColor: AppColors.background,
      dividerColor: AppColors.outlineVariant,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        titleTextStyle: GoogleFonts.almendra(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainer,
        selectedItemColor: AppColors.brandOrange,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandOrangeDeep,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandTurquoise,
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandTurquoise,
          side: const BorderSide(color: AppColors.brandTurquoise, width: 2),
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 48),
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.onSurface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        hintStyle: GoogleFonts.montserrat(
          color: AppColors.onSurfaceVariant,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.brandTurquoise, width: 2),
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.brandOrange,
        inactiveTrackColor: AppColors.outlineVariant,
        thumbColor: AppColors.brandOrange,
        overlayColor: AppColors.brandOrange.withValues(alpha: 0.18),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        margin: EdgeInsets.zero,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.onSurface,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        indicatorColor: AppColors.brandOrange,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandOrange;
          return AppColors.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandOrange.withValues(alpha: 0.4);
          }
          return AppColors.surfaceContainerHigh;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        contentTextStyle: GoogleFonts.montserrat(
          color: AppColors.onSurface,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandOrange,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.onSurfaceVariant,
        textColor: AppColors.onSurface,
      ),
    );
  }
}
