// lib/tenants/nunoa/config.dart
import 'package:frogio_mobile/tenants/tenant_config.dart';
import 'package:flutter/material.dart';

const nunoaConfig = TenantConfig(
  id: 'nunoa',
  name: 'Ñuñoa',
  fullName: 'Municipalidad de Ñuñoa',
  apiBaseUrl: 'https://api-nunoa.supertools.cl',
  ntfyUrl: 'https://ntfy-nunoa.supertools.cl',
  tileServerUrl: 'https://maps.supertools.cl',
  appTitle: 'FROGIO - Ñuñoa',
  primaryColor: Color(0xFF1A237E), // Indigo for Ñuñoa
  primaryDark: Color(0xFF0D1642),
  accentColor: Color(0xFF536DFE),
  appPackageName: 'com.frogio.nunoa',
);
