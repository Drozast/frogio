// lib/core/config/api_config.dart

class ApiConfig {
  // URLs de API - Backend público via Cloudflare Tunnel
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api-frogio.drozast.xyz',
  );

  // Tenant ID (municipalidad)
  static const String tenantId = String.fromEnvironment(
    'TENANT_ID',
    defaultValue: 'santa_juana',
  );

  // Configuración de ntfy para notificaciones
  static const String ntfyUrl = String.fromEnvironment(
    'NTFY_URL',
    defaultValue: 'https://ntfy.drozast.xyz',
  );

  // Self-hosted Maps Services
  static const String tileServerUrl = String.fromEnvironment(
    'TILE_SERVER_URL',
    defaultValue: 'https://maps.drozast.xyz',
  );
  static const String nominatimUrl = String.fromEnvironment(
    'NOMINATIM_URL',
    defaultValue: 'https://geo.drozast.xyz',
  );
  static const String osrmUrl = String.fromEnvironment(
    'OSRM_URL',
    defaultValue: 'https://routing.drozast.xyz',
  );

  // Timeouts
  static const int connectTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000; // 30 segundos

  // Headers por defecto
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'X-Tenant-ID': tenantId,
  };

  // Para desarrollo local / red interna (mismo servidor)
  // Solo se usan si se define DEVELOPMENT=true al compilar
  static const String devBaseUrl = 'http://192.168.31.115:3110';
  static const String devNtfyUrl = 'http://192.168.31.115:8110';

  // Verificar si está en modo desarrollo
  // Por defecto usa Cloudflare (false) - solo local si se define DEVELOPMENT=true
  static bool get isDevelopment => const bool.fromEnvironment(
    'DEVELOPMENT',
    defaultValue: false,
  );

  // URL activa según el modo
  // Por defecto: Cloudflare (seguro desde cualquier red)
  // Con DEVELOPMENT=true: Red local (solo para desarrollo en LAN)
  static String get activeBaseUrl => isDevelopment ? devBaseUrl : baseUrl;
  static String get activeNtfyUrl => isDevelopment ? devNtfyUrl : ntfyUrl;
}
