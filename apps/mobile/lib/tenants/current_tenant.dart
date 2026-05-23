// lib/tenants/current_tenant.dart
import 'package:frogio_mobile/tenants/tenant_config.dart';
import 'santa_juana/config.dart';
import 'nunoa/config.dart';

// This gets overridden at build time via --dart-define
const String _tenantId = String.fromEnvironment('TENANT_ID', defaultValue: 'santa_juana');

TenantConfig get currentTenant {
  switch (_tenantId) {
    case 'nunoa':
      return nunoaConfig;
    default:
      return santaJuanaConfig;
  }
}
