// lib/core/utils/platform_helper.dart
import 'package:flutter/foundation.dart';

class PlatformHelper {
  // Verificar si estamos en una plataforma móvil
  static bool get isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  
  // Verificar si estamos en iOS
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  
  // Verificar si estamos en Android
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  
  // Verificar si estamos en web
  static bool get isWeb => kIsWeb;
  
  // Verificar si estamos en desktop
  static bool get isDesktop => !kIsWeb && (
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.linux
  );
  
  // Obtener el nombre de la plataforma para logging
  static String get platformName {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }
  
  // Verificar si las notificaciones locales están soportadas
  static bool get supportsLocalNotifications => isMobile;
  
  // Verificar si la compresión de imágenes está soportada
  static bool get supportsImageCompression => isMobile;
  
  // Verificar si los permisos están soportados
  static bool get supportsPermissions => isMobile;
}