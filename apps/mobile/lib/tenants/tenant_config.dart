// lib/tenants/tenant_config.dart
import 'package:flutter/material.dart';

class TenantConfig {
  final String id; // 'santa_juana', 'nunoa'
  final String name; // 'Santa Juana', 'Ñuñoa'
  final String fullName; // 'Municipalidad de Santa Juana'
  final String apiBaseUrl; // 'https://api-nunoa.supertools.cl'
  final String ntfyUrl; // notifications
  final String tileServerUrl; // maps
  final String appTitle; // 'FROGIO - Santa Juana'
  final Color primaryColor;
  final Color primaryDark;
  final Color accentColor;
  final String appPackageName; // 'com.frogio.santa_juana'

  const TenantConfig({
    required this.id,
    required this.name,
    required this.fullName,
    required this.apiBaseUrl,
    required this.ntfyUrl,
    required this.tileServerUrl,
    required this.appTitle,
    required this.primaryColor,
    required this.primaryDark,
    required this.accentColor,
    required this.appPackageName,
  });
}
