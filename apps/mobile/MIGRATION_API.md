# 📱 Guía de Migración de Firebase a REST API

## Resumen

Esta guía documenta el proceso de migración de la app móvil FROGIO desde Firebase (Firestore, Auth, Storage) hacia el backend REST API auto-hospedado.

## Estado de la Migración

### ✅ Completado

**1. Autenticación (Auth)**
- ✅ `AuthApiDataSource` creado
- ✅ JWT con access/refresh tokens
- ✅ Storage de tokens en SharedPreferences
- ✅ Auto-refresh de tokens
- ✅ `UserModel.fromApi()` implementado

**2. Reportes Ciudadanos (Reports)**
- ✅ `ReportApiDataSource` creado
- ✅ CRUD completo
- ✅ Upload de imágenes via multipart
- ✅ `ReportModel.fromApi()` implementado

**3. Infracciones (Infractions)**
- ✅ `InfractionApiDataSource` creado
- ✅ CRUD completo
- ✅ Estadísticas
- ✅ Upload de evidencias
- ✅ `InfractionModel.fromApi()` implementado

**4. Configuración**
- ✅ `ApiConfig` creado (URLs, tenant ID, headers)
- ✅ Dependencia `http` agregada
- ✅ `pubspec.yaml` limpiado

### 🟡 Pendiente

**1. Inyección de Dependencias**
- 🟡 Actualizar `injection_container.dart` o crear versión API
- 🟡 Registrar nuevas data sources
- 🟡 Actualizar constructores de BLoCs

**2. Notificaciones**
- 🔴 Migrar de FCM a ntfy.sh
- 🔴 Implementar suscripción a topics
- 🔴 Manejar notificaciones push

**3. Vehículos**
- 🔴 Crear `VehicleApiDataSource`
- 🔴 Implementar endpoints de vehículos

**4. Archivos/Storage**
- 🟡 Integración completa con MinIO
- 🟡 Download de archivos con URLs presignadas

**5. Testing**
- 🔴 Pruebas con API de producción
- 🔴 Manejo de errores
- 🔴 Validación de flujos completos

---

## Arquitectura

### Antes (Firebase)
```
UI (BLoC) → Repository → Firebase DataSource → Firebase Services
                                                  ├─ Auth
                                                  ├─ Firestore
                                                  └─ Storage
```

### Después (REST API)
```
UI (BLoC) → Repository → API DataSource → HTTP Client → Backend REST API
                                                           ├─ /api/auth
                                                           ├─ /api/reports
                                                           ├─ /api/infractions
                                                           └─ /api/files
```

---

## Archivos Creados

### Core
- `/lib/core/config/api_config.dart` - Configuración de API (URLs, tenant, headers)

### Auth
- `/lib/features/auth/data/datasources/auth_api_data_source.dart`
- `/lib/features/auth/data/models/user_model.dart` (método `fromApi()` agregado)

### Reports
- `/lib/features/citizen/data/datasources/report_api_data_source.dart`
- `/lib/features/citizen/data/models/report_model.dart` (método `fromApi()` agregado)

### Infractions
- `/lib/features/inspector/data/datasources/infraction_api_data_source.dart`
- `/lib/features/inspector/data/models/infraction_model.dart` (método `fromApi()` agregado)

### Dependency Injection
- `/lib/di/injection_container_api.dart` (versión REST API - en progreso)

---

## Uso

### Configuración de API

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://api.drozast.xyz';
  static const String tenantId = 'santa_juana';
  static const String ntfyUrl = 'https://ntfy.drozast.xyz';
}
```

### Autenticación

```dart
// Login
final authDataSource = AuthApiDataSource(
  client: http.Client(),
  prefs: await SharedPreferences.getInstance(),
  baseUrl: ApiConfig.baseUrl,
  tenantId: ApiConfig.tenantId,
);

final user = await authDataSource.signInWithEmailAndPassword(
  'usuario@ejemplo.cl',
  'password123',
);

// Tokens almacenados automáticamente en SharedPreferences
// - access_token (15 min)
// - refresh_token (7 días)
```

### Crear Reporte

```dart
final reportDataSource = ReportApiDataSource(
  client: http.Client(),
  prefs: prefs,
  baseUrl: ApiConfig.baseUrl,
);

final reportId = await reportDataSource.createReport(
  title: 'Semáforo dañado',
  description: 'El semáforo de Av. Principal está sin luz',
  category: 'complaint',
  location: LocationData(
    latitude: -36.9934,
    longitude: -72.7044,
    address: 'Av. Principal esquina Libertad',
  ),
  userId: currentUserId,
  images: [File('/path/to/image.jpg')],
);
```

### Obtener Infracciones

```dart
final infractionDataSource = InfractionApiDataSource(
  client: http.Client(),
  prefs: prefs,
  baseUrl: ApiConfig.baseUrl,
);

final infractions = await infractionDataSource.getInfractionsByInspector(inspectorId);

// Estadísticas
final stats = await infractionDataSource.getInfractionStatistics('santa_juana');
print('Total: ${stats['total']}');
print('Pendientes: ${stats['pendientes']}');
print('Pagadas: ${stats['pagadas']}');
```

---

## Mapeo de Datos

### Status (Estados)

| App (Antiguo) | API (Backend) |
|---------------|---------------|
| `Pendiente` | `pendiente` |
| `En proceso` | `en_proceso` |
| `Resuelto` | `resuelto` |
| `Rechazado` | `rechazado` |

### Report Types (Tipos de Reporte)

| App | Backend |
|-----|---------|
| `denuncia` | `complaint` |
| `sugerencia` | `suggestion` |
| `emergencia` | `emergency` |
| `solicitud` | `request` |
| `incidente` | `incident` |

### Infraction Status

| App | Backend |
|-----|---------|
| `created` / `pendiente` | `pendiente` |
| `paid` / `pagada` | `pagada` |
| `cancelled` / `anulada` | `anulada` |

---

## Endpoints Implementados

### Autenticación

- `POST /api/auth/register` - Registrar usuario
- `POST /api/auth/login` - Iniciar sesión
- `POST /api/auth/logout` - Cerrar sesión
- `POST /api/auth/refresh` - Refrescar token
- `GET /api/auth/me` - Obtener usuario actual
- `PATCH /api/auth/profile` - Actualizar perfil

### Reportes

- `GET /api/reports` - Listar reportes del usuario
- `GET /api/reports/:id` - Obtener reporte por ID
- `POST /api/reports` - Crear nuevo reporte
- `PATCH /api/reports/:id` - Actualizar reporte
- `DELETE /api/reports/:id` - Eliminar reporte

### Infracciones

- `GET /api/infractions` - Listar infracciones
- `GET /api/infractions/:id` - Obtener infracción por ID
- `GET /api/infractions/stats` - Obtener estadísticas
- `POST /api/infractions` - Crear nueva infracción
- `PATCH /api/infractions/:id` - Actualizar infracción
- `DELETE /api/infractions/:id` - Eliminar infracción

### Archivos

- `POST /api/files/upload` - Subir archivo (multipart/form-data)
- `GET /api/files/:id/url` - Obtener URL presignada de descarga
- `GET /api/files/:entityType/:entityId` - Listar archivos de entidad
- `DELETE /api/files/:id` - Eliminar archivo

---

## Manejo de Errores

```dart
try {
  final user = await authDataSource.signInWithEmailAndPassword(email, password);
} on Exception catch (e) {
  if (e.toString().contains('401')) {
    // Credenciales inválidas
  } else if (e.toString().contains('Network')) {
    // Sin conexión
  } else {
    // Error general
  }
}
```

---

## Variables de Entorno

Para configurar la app en diferentes entornos:

```bash
# Producción
flutter run --dart-define=API_URL=https://api.drozast.xyz \
            --dart-define=TENANT_ID=santa_juana

# Desarrollo local
flutter run --dart-define=API_URL=http://localhost:3000 \
            --dart-define=TENANT_ID=santa_juana \
            --dart-define=DEVELOPMENT=true
```

---

## Próximos Pasos

1. **Actualizar Dependency Injection**
   - Modificar `lib/di/injection_container.dart`
   - Reemplazar Firebase data sources con API data sources
   - Actualizar constructores de BLoCs

2. **Migrar Notificaciones**
   - Implementar cliente ntfy
   - Suscripción a topics: `{tenantId}_{userId}`
   - Manejar notificaciones en background

3. **Implementar Vehículos**
   - Crear `VehicleApiDataSource`
   - Endpoints CRUD de vehículos
   - Búsqueda por patente

4. **Testing**
   - Probar flujos completos
   - Manejo de errores de red
   - Validación de tokens expirados

5. **Opcional: Remover Firebase**
   - Eliminar dependencias de Firebase
   - Limpiar código antiguo
   - Reducir tamaño de APK

---

## Notas Importantes

- **Tokens**: Access token expira en 15 min, refresh token en 7 días
- **Storage**: Archivos se suben a MinIO (compatible S3)
- **Headers**: Siempre incluir `X-Tenant-ID: santa_juana` en login/register
- **Autorización**: Incluir `Authorization: Bearer {token}` en requests autenticados
- **IDs**: Backend usa UUIDs, no Firestore document IDs
- **Fechas**: Backend usa ISO 8601 strings, parsear con `DateTime.parse()`

---

## Documentación de Referencia

- Backend API: `/apps/backend/API.md`
- Deployment: `/DEPLOYMENT_GUIDE.md`
- Arquitectura: `/ARQUITECTURA_FINAL.md`

---

Última actualización: 2025-12-14
