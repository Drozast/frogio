// lib/core/config/api_config.dart

import 'package:frogio_mobile/tenants/current_tenant.dart';

class ApiConfig {
  // URLs de API - Backend público via Cloudflare Tunnel
  // Environment variables take precedence, tenant config provides defaults
  static String get baseUrl {
    const env = String.fromEnvironment('API_URL', defaultValue: '');
    return env.isNotEmpty ? env : currentTenant.apiBaseUrl;
  }

  // Tenant ID (municipalidad)
  static String get tenantId {
    const env = String.fromEnvironment('TENANT_ID', defaultValue: '');
    return env.isNotEmpty ? env : currentTenant.id;
  }

  // Configuración de ntfy para notificaciones
  static String get ntfyUrl {
    const env = String.fromEnvironment('NTFY_URL', defaultValue: '');
    return env.isNotEmpty ? env : currentTenant.ntfyUrl;
  }

  // Self-hosted Maps Services
  static String get tileServerUrl {
    const env = String.fromEnvironment('TILE_SERVER_URL', defaultValue: '');
    return env.isNotEmpty ? env : currentTenant.tileServerUrl;
  }

  static const String nominatimUrl = String.fromEnvironment(
    'NOMINATIM_URL',
    defaultValue: 'https://geo.supertools.cl',
  );
  static const String osrmUrl = String.fromEnvironment(
    'OSRM_URL',
    defaultValue: 'https://routing.supertools.cl',
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

  // App package name from tenant config (for maps tile provider)
  static String get appPackageName => currentTenant.appPackageName;
}
