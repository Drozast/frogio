// lib/tenants/santa_juana/config.dart
import 'package:frogio_mobile/tenants/tenant_config.dart';
import 'package:flutter/material.dart';

const santaJuanaConfig = TenantConfig(
  id: 'santa_juana',
  name: 'Santa Juana',
  fullName: 'Municipalidad de Santa Juana',
  apiBaseUrl: 'https://api-frogio.supertools.cl',
  ntfyUrl: 'https://ntfy.supertools.cl',
  tileServerUrl: 'https://maps.supertools.cl',
  appTitle: 'FROGIO - Santa Juana',
  primaryColor: Color(0xFF4CAF50),
  primaryDark: Color(0xFF2E7D32),
  accentColor: Color(0xFF69F0AE),
  appPackageName: 'com.frogio.santa_juana',
);
