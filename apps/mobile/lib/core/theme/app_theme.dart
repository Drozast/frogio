// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sistema de diseño FROGIO - Estilo Moderno Minimalista
///
/// Principios:
/// - Mucho espacio en blanco para respirar
/// - Sombras sutiles y elevaciones mínimas
/// - Tipografía clara con jerarquía definida
/// - Colores con propósito y significado
/// - Microinteracciones elegantes
class AppTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // PALETA DE COLORES PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════

  // Colores primarios - Paleta "Verde Sapo / Frog Green"
  static const Color primary = Color(0xFF4CAF50);           // Verde sapo principal
  static const Color primaryLight = Color(0xFFA5D6A7);      // Verde claro (backgrounds sutiles)
  static const Color primaryDark = Color(0xFF2E7D32);       // Verde oscuro (botones, headers)
  static const Color primarySurface = Color(0xFFE8F5E9);    // Verde muy suave para fondos

  // Colores de acento
  static const Color accent = Color(0xFF69F0AE);            // Verde neon para efectos glow
  static const Color accentLight = Color(0xFFA5D6A7);       // Verde suave

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES SEMÁNTICOS (Estados y feedback)
  // ═══════════════════════════════════════════════════════════════════════════

  // Emergencia / Peligro
  static const Color emergency = Color(0xFFD32F2F);         // Rojo emergencia
  static const Color emergencyLight = Color(0xFFFFCDD2);    // Fondo rojo suave
  static const Color emergencyDark = Color(0xFFB71C1C);     // Rojo oscuro

  // Advertencia
  static const Color warning = Color(0xFFF57C00);           // Naranja advertencia
  static const Color warningLight = Color(0xFFFFE0B2);      // Fondo naranja suave

  // Éxito
  static const Color success = Color(0xFF388E3C);           // Verde éxito
  static const Color successLight = Color(0xFFC8E6C9);      // Fondo verde suave

  // Información
  static const Color info = Color(0xFF1976D2);              // Azul información
  static const Color infoLight = Color(0xFFBBDEFB);         // Fondo azul suave

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES NEUTRALES (Minimalista)
  // ═══════════════════════════════════════════════════════════════════════════

  // Superficies
  static const Color surface = Color(0xFFF0F7F0);           // Fondo principal (blanco con tinte verde sutil)
  static const Color surfaceWhite = Color(0xFFFFFFFF);      // Blanco puro para cards
  static const Color surfaceElevated = Color(0xFFFFFFFF);   // Tarjetas elevadas

  // Texto
  static const Color textPrimary = Color(0xFF1B3A1B);       // Verde muy oscuro casi negro
  static const Color textSecondary = Color(0xFF4A6741);     // Verde medio para subtítulos
  static const Color textTertiary = Color(0xFF8DAF8D);      // Texto deshabilitado/hints
  static const Color textOnPrimary = Color(0xFFFFFFFF);     // Blanco solo sobre botones verdes

  // Bordes y divisores
  static const Color border = Color(0xFFE0E0E0);            // Bordes sutiles
  static const Color borderLight = Color(0xFFF5F5F5);       // Bordes muy sutiles
  static const Color divider = Color(0xFFEEEEEE);           // Divisores

  // ═══════════════════════════════════════════════════════════════════════════
  // ESPACIADO (Sistema de 4px)
  // ═══════════════════════════════════════════════════════════════════════════

  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing64 = 64;

  // ═══════════════════════════════════════════════════════════════════════════
  // RADIOS DE BORDE
  // ═══════════════════════════════════════════════════════════════════════════

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusRound = 100;    // Para píldoras y círculos

  // ═══════════════════════════════════════════════════════════════════════════
  // ELEVACIONES (Sombras sutiles minimalistas)
  // ═══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Sombra para botón SOS (emergencia)
  static List<BoxShadow> shadowEmergency(bool isActive) => [
    BoxShadow(
      color: (isActive ? success : emergency).withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // Neon glow para botones principales y cards
  static List<BoxShadow> get neonGlow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: accent.withValues(alpha: 0.2),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  // Card con borde neon verde
  static BoxDecoration get neonCardDecoration => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: primary.withValues(alpha: 0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: primary.withValues(alpha: 0.15),
        blurRadius: 16,
        spreadRadius: 1,
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TIPOGRAFÍA
  // ═══════════════════════════════════════════════════════════════════════════

  static const String fontFamily = 'Montserrat';

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTES
  // ═══════════════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [primaryDark, primary, Color(0xFF66BB6A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF0F7F0), surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [emergencyDark, emergency],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryDark, primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFEEEEEE),
      Color(0xFFF5F5F5),
      Color(0xFFEEEEEE),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, 0),
    end: Alignment(1.0, 0),
  );

  // Display - Para números grandes y headlines
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    color: textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  // Headlines
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: textPrimary,
  );

  // Títulos
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: textSecondary,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textTertiary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORACIONES DE CONTENEDORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tarjeta elevada estándar
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: shadowSmall,
  );

  /// Tarjeta con borde sutil
  static BoxDecoration get cardBorderedDecoration => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: border, width: 1),
  );

  /// Glass morphism card decoration
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: surfaceWhite.withValues(alpha: 0.8),
    borderRadius: BorderRadius.circular(radiusXLarge),
    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Premium card with accent border
  static BoxDecoration premiumCardDecoration(Color accentColor) => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: accentColor.withValues(alpha: 0.15), width: 1),
    boxShadow: [
      BoxShadow(
        color: accentColor.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Tarjeta destacada (para CTAs)
  static BoxDecoration cardHighlightDecoration(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
  );

  /// Chip/Badge
  static BoxDecoration chipDecoration(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(radiusRound),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMA LIGHT (Principal)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Default light theme using Santa Juana colors (backward compatible).
  static ThemeData get lightTheme => lightThemeFor(
    primaryColor: primary,
    primaryDarkColor: primaryDark,
    accentColorValue: accent,
  );

  /// Builds a light theme with tenant-configurable brand colors.
  /// All other tokens (spacing, typography, shadows, etc.) remain consistent.
  static ThemeData lightThemeFor({
    required Color primaryColor,
    required Color primaryDarkColor,
    required Color accentColorValue,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,

      // Colores
      primaryColor: primaryColor,
      scaffoldBackgroundColor: surface,

      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primarySurface,
        secondary: accentColorValue,
        secondaryContainer: accentLight,
        surface: surface,
        error: emergency,
        errorContainer: emergencyLight,
        onPrimary: textOnPrimary,
        onSecondary: textOnPrimary,
        onSurface: textPrimary,
        onError: textOnPrimary,
        outline: border,
      ),

      // AppBar minimalista
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: titleLarge,
        iconTheme: IconThemeData(color: textPrimary, size: 24),
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: labelLarge.copyWith(color: textOnPrimary),
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: labelLarge,
        ),
      ),

      // Botones outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: labelLarge,
        ),
      ),

      // Inputs minimalistas
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: emergency),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: emergency, width: 2),
        ),
        labelStyle: bodyMedium.copyWith(color: textSecondary),
        hintStyle: bodyMedium.copyWith(color: textTertiary),
        errorStyle: bodySmall.copyWith(color: emergency),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // Tarjetas
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: primarySurface,
        labelStyle: labelMedium.copyWith(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusRound),
        ),
        side: BorderSide.none,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: labelSmall,
        unselectedLabelStyle: labelSmall,
      ),

      // FloatingActionButton con neon glow
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 4,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // SnackBars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: bodyMedium.copyWith(color: textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        titleTextStyle: headlineSmall,
        contentTextStyle: bodyLarge,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXLarge),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: border,
      ),

      // Lista de tiles
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        titleTextStyle: titleSmall,
        subtitleTextStyle: bodySmall,
        iconColor: textSecondary,
      ),

      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primarySurface,
        circularTrackColor: primarySurface,
      ),

      // Page transitions - iOS style slide (smoother)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS DE ESTILO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene el color según el estado de un reporte
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pendiente':
      case 'enviada':
        return warning;
      case 'in_progress':
      case 'en_revision':
      case 'en_proceso':
        return info;
      case 'resolved':
      case 'resuelta':
      case 'completada':
        return success;
      case 'rejected':
      case 'rechazada':
      case 'cancelada':
        return emergency;
      default:
        return textSecondary;
    }
  }

  /// Obtiene el color de fondo según el estado
  static Color getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pendiente':
      case 'enviada':
        return warningLight;
      case 'in_progress':
      case 'en_revision':
      case 'en_proceso':
        return infoLight;
      case 'resolved':
      case 'resuelta':
      case 'completada':
        return successLight;
      case 'rejected':
      case 'rechazada':
      case 'cancelada':
        return emergencyLight;
      default:
        return surface;
    }
  }

  // Colores legacy para compatibilidad
  static const Color primaryColor = primary;
  static const Color secondaryColor = accent;
  static const Color accentColor = accentLight;
  static const Color darkGreen = primaryDark;
  static const Color backgroundLight = surface;
  static const Color backgroundDark = Color(0xFF121212);
  static const Color textDark = textPrimary;
  static const Color textLight = textOnPrimary;
  static const Color successColor = success;
  static const Color warningColor = warning;
  static const Color errorColor = emergency;
}
