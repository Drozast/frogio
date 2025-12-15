# Análisis Completo de la Aplicación Flutter FROGIO
## Sistema de Gestión de Seguridad Pública Municipal

**Fecha de análisis**: 15 de Diciembre, 2025
**Versión analizada**: Prototipo funcional original
**Arquitectura**: Clean Architecture + BLoC Pattern

---

## 📱 DESCRIPCIÓN GENERAL

FROGIO es una aplicación móvil multiplataforma (iOS/Android) que sirve como herramienta de gestión para seguridad pública municipal. La aplicación tiene **3 roles principales**:

1. **Ciudadano** (citizen) - Para reportar problemas y hacer consultas
2. **Inspector** (inspector) - Para gestionar infracciones y tareas de campo
3. **Administrador** (admin) - Para supervisión y gestión (NOTA: El admin debería usar la versión web)

---

## 🏗️ ARQUITECTURA

### Clean Architecture (Capas)

```
lib/
├── core/                          # Funcionalidades compartidas
│   ├── blocs/                     # BLoCs globales
│   ├── services/                  # Servicios compartidos
│   ├── theme/                     # Temas y estilos
│   ├── utils/                     # Utilidades
│   └── widgets/                   # Widgets reutilizables
│
├── features/                      # Módulos por característica
│   ├── auth/                      # Autenticación
│   │   ├── data/
│   │   │   ├── datasources/      # API calls
│   │   │   └── repositories/      # Implementación de repositorios
│   │   ├── domain/
│   │   │   ├── entities/         # Modelos de dominio
│   │   │   ├── repositories/     # Contratos de repositorios
│   │   │   └── usecases/         # Casos de uso (lógica de negocio)
│   │   └── presentation/
│   │       ├── bloc/             # Estado y eventos
│   │       ├── pages/            # Pantallas
│   │       └── widgets/          # Componentes UI
│   │
│   ├── citizen/                   # Módulo de ciudadano
│   ├── inspector/                 # Módulo de inspector
│   └── admin/                     # Módulo de administrador
│
├── dashboard/                     # Pantalla principal
└── di/                           # Dependency Injection
```

### Patrón BLoC (Business Logic Component)

- **Bloc**: Maneja el estado de la aplicación
- **Events**: Acciones del usuario
- **States**: Estados de la UI
- Separación clara entre UI y lógica de negocio

---

## 🎯 MÓDULOS Y FUNCIONALIDADES

### 1. MÓDULO DE AUTENTICACIÓN (Auth)

#### Pantallas:
- **SplashScreen**: Pantalla inicial con validación de sesión
- **LoginScreen**: Inicio de sesión con email/password
- **RegisterScreen**: Registro de nuevos usuarios
- **EditProfileScreen**: Edición de perfil con avatar

#### Funcionalidades:
- ✅ Login con email/password
- ✅ Registro de usuarios con validación
- ✅ Persistencia de sesión (tokens JWT)
- ✅ Recuperación de contraseña (forgot password)
- ✅ Edición de perfil (nombre, teléfono, dirección, avatar)
- ✅ Subida de imagen de perfil
- ✅ Logout
- ✅ Session timeout (inactividad)
- ✅ Validación de perfil completo

#### Entidades:
```dart
class UserEntity {
  String id;
  String email;
  String displayName;
  String? phoneNumber;
  String? address;
  String? photoURL;
  String role;                 // citizen, inspector, admin
  bool isProfileComplete;
  DateTime createdAt;
}
```

#### Casos de Uso:
- `SignInUser` - Inicio de sesión
- `SignOutUser` - Cerrar sesión
- `RegisterUser` - Registro
- `GetCurrentUser` - Obtener usuario actual
- `UpdateUserProfile` - Actualizar perfil
- `UploadProfileImage` - Subir avatar
- `ForgotPassword` - Recuperar contraseña

---

### 2. MÓDULO CIUDADANO (Citizen)

#### Pantallas:
- **CreateReportScreen / EnhancedCreateReportScreen**: Crear denuncias
- **MyReportsScreen / EnhancedMyReportsScreen**: Ver mis denuncias
- **ReportDetailScreen / EnhancedReportDetailScreen**: Detalle de denuncia

#### Funcionalidades:

##### 2.1 Denuncias (Reports)
- ✅ Crear nueva denuncia con:
  - Título y descripción
  - Categoría
  - Referencias (opcional)
  - Ubicación (GPS, mapa o manual)
  - Fotos y videos adjuntos
  - Prioridad
- ✅ Ver mis denuncias filtradas por estado
- ✅ Ver detalle completo de denuncia
- ✅ Ver historial de estados
- ✅ Ver respuestas de la municipalidad
- ✅ Seguimiento en tiempo real
- ✅ Notificaciones push cuando cambia el estado

##### 2.2 Ubicación (Location Picker)
- **Tres métodos de captura**:
  1. **GPS**: Ubicación automática del dispositivo
  2. **Mapa interactivo**: Seleccionar punto en mapa
  3. **Manual**: Escribir dirección manualmente
- ✅ Geocoding reverso (coordenadas → dirección)
- ✅ Vista previa en mapa
- ✅ Validación de ubicación

##### 2.3 Adjuntos Multimedia
- ✅ Subir múltiples fotos
- ✅ Subir videos
- ✅ Captura desde cámara
- ✅ Selección desde galería
- ✅ Vista previa de adjuntos
- ✅ Compresión de imágenes

#### Entidades Principales:

```dart
class ReportEntity {
  String id;
  String title;
  String description;
  String category;
  String? references;
  LocationData location;
  String citizenId;
  String muniId;
  ReportStatus status;              // draft, submitted, reviewing, inProgress, resolved, rejected, archived
  Priority priority;                // low, medium, high, urgent
  List<MediaAttachment> attachments;
  DateTime createdAt;
  DateTime updatedAt;
  List<StatusHistoryItem> statusHistory;
  List<ReportResponse> responses;
  String? assignedToId;
  String? assignedToName;
}

class LocationData {
  double latitude;
  double longitude;
  String? address;
  String? manualAddress;
  LocationSource source;            // gps, map, manual
}

class MediaAttachment {
  String id;
  String url;
  String fileName;
  MediaType type;                   // image, video
  int? fileSize;
  DateTime uploadedAt;
}

class StatusHistoryItem {
  DateTime timestamp;
  ReportStatus status;
  String? comment;
  String? userId;
  String? userName;
}

class ReportResponse {
  String id;
  String responderId;
  String responderName;
  String message;
  List<MediaAttachment> attachments;
  bool isPublic;
  DateTime createdAt;
}
```

#### Estados de Denuncia:
1. **draft** - Borrador
2. **submitted** - Enviada
3. **reviewing** - En Revisión
4. **inProgress** - En Proceso
5. **resolved** - Resuelta
6. **rejected** - Rechazada
7. **archived** - Archivada

#### Casos de Uso:
- `CreateReport` - Crear denuncia
- `GetReportsByUser` - Obtener denuncias del usuario
- `GetReportById` - Obtener detalle de denuncia
- `EnhancedReportUseCases` - Casos de uso avanzados

##### 2.4 Consultas (Queries) - EN DESARROLLO
- ⏳ Crear consultas a la municipalidad
- ⏳ Ver mis consultas
- ⏳ Ver respuestas
- ⏳ Estado de consultas

---

### 3. MÓDULO INSPECTOR (Inspector)

#### Pantallas:
- **Tareas Pendientes**: Lista de denuncias asignadas
- **Crear Infracción**: Registrar nueva infracción
- **Mis Infracciones**: Ver infracciones creadas
- **Registro de Vehículos**: Gestionar vehículos

#### Funcionalidades:

##### 3.1 Infracciones (Infractions)
- ✅ Crear nueva infracción con:
  - Título y descripción
  - Referencia a ordenanza municipal
  - Ubicación GPS
  - Datos del infractor (nombre, documento)
  - Evidencia fotográfica
  - Firmas digitales
- ✅ Ver mis infracciones
- ✅ Actualizar estado de infracción
- ✅ Subir evidencia
- ✅ Historial de cambios

##### 3.2 Gestión de Tareas
- ✅ Ver denuncias asignadas
- ✅ Actualizar estado de denuncias
- ✅ Agregar respuestas con fotos
- ✅ Cambiar prioridad

##### 3.3 Registro de Vehículos
- ⏳ Registrar vehículos infractores
- ⏳ Búsqueda por patente
- ⏳ Historial de infracciones por vehículo

#### Entidades:

```dart
class InfractionEntity {
  String id;
  String title;
  String description;
  String ordinanceRef;              // Referencia a ordenanza
  LocationData location;
  String offenderId;
  String offenderName;
  String offenderDocument;
  String inspectorId;
  String muniId;
  List<String> evidence;            // URLs de evidencia
  List<String> signatures;          // URLs de firmas
  InfractionStatus status;
  DateTime createdAt;
  DateTime updatedAt;
  List<InfractionHistoryItem> historyLog;
}
```

#### Estados de Infracción:
1. **created** - Creada
2. **signed** - Firmada
3. **submitted** - Enviada
4. **reviewed** - Revisada
5. **appealed** - Apelada
6. **confirmed** - Confirmada
7. **cancelled** - Cancelada
8. **paid** - Pagada
9. **pending** - Pendiente

#### Casos de Uso:
- `CreateInfraction` - Crear infracción
- `GetInfractionsByInspector` - Obtener infracciones del inspector
- `UpdateInfractionStatus` - Actualizar estado
- `UploadInfractionImage` - Subir evidencia

---

### 4. MÓDULO ADMINISTRADOR (Admin)

**IMPORTANTE**: Este módulo debería migrar completamente a la versión web. La app móvil de admin es solo para consulta rápida.

#### Funcionalidades:
- ✅ Ver estadísticas municipales
- ✅ Gestión de usuarios (activar/desactivar)
- ✅ Cambiar roles de usuarios
- ✅ Ver todas las consultas pendientes
- ✅ Responder consultas
- ✅ Dashboard con métricas

#### Entidades:

```dart
class MunicipalStatisticsEntity {
  int totalReports;
  int pendingReports;
  int resolvedReports;
  int totalInfractions;
  int totalUsers;
  int activeUsers;
  Map<String, int> reportsByCategory;
  Map<String, int> reportsByStatus;
}

class QueryEntity {
  String id;
  String question;
  String? answer;
  String userId;
  String userName;
  bool isAnswered;
  DateTime createdAt;
  DateTime? answeredAt;
}
```

#### Casos de Uso:
- `GetMunicipalStatistics` - Obtener estadísticas
- `GetAllUsers` - Listar usuarios
- `ActivateUser` / `DeactivateUser` - Gestión de usuarios
- `UpdateUserRole` - Cambiar rol
- `GetAllPendingQueries` - Consultas pendientes
- `AnswerQuery` - Responder consulta

---

## 🔧 SERVICIOS CORE

### 1. Notification Service (Notificaciones)
- **Firebase Cloud Messaging (FCM)**
- Notificaciones push en tiempo real
- Manejo de notificaciones en foreground/background
- Deep linking a pantallas específicas
- Badge de notificaciones no leídas
- Pantalla de historial de notificaciones

#### Tipos de Notificaciones:
- Cambio de estado de denuncia
- Asignación de tarea a inspector
- Respuesta a consulta
- Nueva infracción creada
- Recordatorios

### 2. Maps Service (Mapas)
- **Google Maps** o **Mapbox**
- Vista de mapa interactivo
- Marcadores personalizados
- Geocoding y reverse geocoding
- Búsqueda de direcciones
- Ruta entre puntos
- Mapa de calor de denuncias

### 3. Session Timeout Service
- Cierre automático de sesión por inactividad
- Tiempo configurable (default: 15 minutos)
- Detección de actividad del usuario
- Diálogo de advertencia antes de cerrar sesión

### 4. Image Helper Service
- Compresión de imágenes
- Redimensionamiento
- Conversión de formatos
- Soporte para plataforma web
- Caché de imágenes

---

## 🎨 DASHBOARD PRINCIPAL

### Navegación por Roles

#### Ciudadano:
```
Bottom Navigation:
├── 🏠 Inicio
├── 📋 Denuncias
├── ❓ Consultas
└── 👤 Perfil

Accesos Rápidos:
├── ➕ Nueva Denuncia
├── 📋 Mis Denuncias
├── ❓ Nueva Consulta
└── 🔍 Mis Consultas
```

#### Inspector:
```
Bottom Navigation:
├── 🏠 Inicio
├── 📝 Tareas
├── ⚖️ Infracciones
├── 🚗 Vehículos
└── 👤 Perfil

Accesos Rápidos:
├── 📝 Tareas Pendientes
├── ⚖️ Nueva Infracción
├── 🚗 Registro Vehículo
└── 🗺️ Mapa
```

#### Administrador (Migrar a Web):
```
Bottom Navigation:
├── 🏠 Inicio
├── 📊 Estadísticas
├── 👥 Usuarios
├── ⚙️ Configuración
└── 👤 Perfil

Accesos Rápidos:
├── 📊 Estadísticas
├── 👥 Usuarios
├── 🚨 Denuncias Pendientes
└── ⚙️ Configuración
```

---

## 🔐 SEGURIDAD

### Autenticación:
- JWT Tokens (Access + Refresh)
- Tokens almacenados en almacenamiento seguro (FlutterSecureStorage)
- Renovación automática de tokens
- Logout en caso de token inválido

### Autorización:
- Middleware de verificación de roles
- Restricción de pantallas por rol
- Validación de permisos en cada acción

### Validaciones:
- Email válido
- Contraseña fuerte (8+ caracteres, mayúsculas, números)
- RUT chileno válido
- Teléfono con formato correcto
- Campos obligatorios

---

## 📡 INTEGRACIÓN CON BACKEND

### Endpoints Utilizados:

#### Auth:
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Registro
- `POST /api/auth/refresh` - Renovar token
- `POST /api/auth/forgot-password` - Recuperar contraseña
- `GET /api/auth/me` - Usuario actual
- `PUT /api/auth/profile` - Actualizar perfil
- `POST /api/auth/upload-avatar` - Subir avatar

#### Reports (Ciudadano):
- `POST /api/reports` - Crear denuncia
- `GET /api/reports/user/:userId` - Denuncias del usuario
- `GET /api/reports/:id` - Detalle de denuncia
- `PUT /api/reports/:id/status` - Actualizar estado
- `POST /api/reports/:id/response` - Agregar respuesta
- `POST /api/reports/upload-media` - Subir archivo

#### Infractions (Inspector):
- `POST /api/infractions` - Crear infracción
- `GET /api/infractions/inspector/:inspectorId` - Infracciones del inspector
- `PUT /api/infractions/:id/status` - Actualizar estado
- `POST /api/infractions/upload-evidence` - Subir evidencia

#### Admin:
- `GET /api/admin/statistics` - Estadísticas
- `GET /api/admin/users` - Listar usuarios
- `PUT /api/admin/users/:id/activate` - Activar usuario
- `PUT /api/admin/users/:id/deactivate` - Desactivar usuario
- `PUT /api/admin/users/:id/role` - Cambiar rol
- `GET /api/admin/queries` - Consultas pendientes
- `POST /api/admin/queries/:id/answer` - Responder consulta

#### Notifications:
- `POST /api/notifications/register-token` - Registrar FCM token
- `GET /api/notifications` - Historial de notificaciones
- `PUT /api/notifications/:id/read` - Marcar como leída

---

## 📊 CARACTERÍSTICAS TÉCNICAS

### Estado (State Management):
- **BLoC Pattern** (flutter_bloc)
- Estados globales: AuthBloc, NotificationBloc
- Estados locales por feature
- Eventos tipados
- Estados inmutables (Equatable)

### Dependency Injection:
- **GetIt** (service locator)
- Registro de dependencias en `injection_container.dart`
- Lazy singletons para servicios
- Factory para BLoCs

### Storage:
- **SharedPreferences** - Preferencias simples
- **FlutterSecureStorage** - Tokens y datos sensibles
- **Hive** (opcional) - Caché local de datos

### Networking:
- **Dio** - Cliente HTTP
- Interceptores para tokens
- Manejo de errores
- Retry automático
- Timeout configurables

### Imágenes:
- **image_picker** - Selección de galería/cámara
- **cached_network_image** - Caché de imágenes de red
- **flutter_image_compress** - Compresión

### Mapas:
- **google_maps_flutter** - Google Maps
- **geolocator** - Geolocalización
- **geocoding** - Geocoding/Reverse geocoding

### Firebase:
- **firebase_core** - Configuración
- **firebase_messaging** - Push notifications
- **firebase_analytics** (opcional) - Analytics

### UI/UX:
- **Material Design 3**
- Animaciones con AnimationController
- Transiciones suaves
- Loading states
- Error handling visual
- Validación en tiempo real

---

## 🎯 FLUJOS PRINCIPALES

### 1. Flujo de Login:
```
SplashScreen
  ↓ (checkAuthStatus)
  ├─ Token válido → Dashboard
  └─ No token → LoginScreen
       ↓ (login exitoso)
       → Dashboard (según rol)
```

### 2. Flujo de Creación de Denuncia (Ciudadano):
```
Dashboard → Nueva Denuncia
  ↓
EnhancedCreateReportScreen
  ├─ Ingresar título/descripción
  ├─ Seleccionar categoría
  ├─ Elegir ubicación (GPS/Mapa/Manual)
  ├─ Agregar fotos/videos
  ├─ Seleccionar prioridad
  ↓
Validar perfil completo
  ↓ (si es completo)
Crear denuncia
  ↓
Notificación de éxito
  ↓
MyReportsScreen (ver denuncia creada)
```

### 3. Flujo de Creación de Infracción (Inspector):
```
Dashboard → Nueva Infracción
  ↓
CreateInfractionScreen
  ├─ Ingresar datos del infractor
  ├─ Referencia a ordenanza
  ├─ Ubicación GPS automática
  ├─ Tomar fotos de evidencia
  ├─ Capturar firma digital
  ↓
Crear infracción
  ↓
Notificación de éxito
  ↓
Mis Infracciones
```

### 4. Flujo de Actualización de Estado (Inspector):
```
Tareas Pendientes
  ↓ (seleccionar denuncia)
ReportDetailScreen
  ↓ (agregar respuesta)
  ├─ Escribir comentario
  ├─ Adjuntar fotos
  ├─ Cambiar estado
  ↓
Actualizar denuncia
  ↓
Notificación al ciudadano
```

---

## 🚀 CARACTERÍSTICAS PENDIENTES/EN DESARROLLO

### Ciudadano:
- ⏳ Módulo de consultas completo
- ⏳ Chat en vivo con municipalidad
- ⏳ Valoración de resolución de denuncias
- ⏳ Historial de denuncias en mapa
- ⏳ Filtros avanzados de búsqueda

### Inspector:
- ⏳ Módulo de vehículos completo
- ⏳ Escáner de patentes (OCR)
- ⏳ Rutas optimizadas de inspección
- ⏳ Modo offline con sincronización
- ⏳ Reportes diarios/semanales

### Admin (Migrar a Web):
- ⏳ Dashboard avanzado con gráficos
- ⏳ Exportación de reportes (PDF/Excel)
- ⏳ Gestión de categorías
- ⏳ Configuración de ordenanzas
- ⏳ Asignación automática de tareas

### Generales:
- ⏳ Modo oscuro
- ⏳ Internacionalización (i18n)
- ⏳ Modo offline robusto
- ⏳ Sincronización en background
- ⏳ Tests unitarios y de integración

---

## 📋 RECOMENDACIONES PARA DESARROLLO WEB/MOBILE

### WEB (Next.js) - Solo Admin:
**Debe incluir TODO lo que hace el admin en mobile + más:**

1. **Dashboard avanzado**:
   - Gráficos de denuncias por categoría, estado, zona
   - Métricas en tiempo real
   - KPIs municipales
   - Mapa de calor de incidentes

2. **Gestión de usuarios**:
   - CRUD completo de usuarios
   - Asignación de roles
   - Permisos granulares
   - Logs de actividad

3. **Gestión de denuncias**:
   - Ver todas las denuncias (tabla con filtros)
   - Asignar a inspectores
   - Cambiar estados masivamente
   - Exportar reportes

4. **Gestión de infracciones**:
   - Ver todas las infracciones
   - Revisión y aprobación
   - Gestión de apelaciones
   - Seguimiento de pagos

5. **Configuración del sistema**:
   - Categorías de denuncias
   - Ordenanzas municipales
   - Plantillas de notificaciones
   - Parámetros del sistema

6. **Reportes y Analytics**:
   - Reportes personalizados
   - Exportación a PDF/Excel
   - Gráficos interactivos
   - Comparativas temporales

### MOBILE (Flutter) - Ciudadano + Inspector:

**Ciudadano**:
- Mantener TODO lo actual
- Completar módulo de consultas
- Mejorar UX de creación de denuncias
- Agregar sistema de valoración

**Inspector**:
- Mantener TODO lo actual
- Completar módulo de vehículos
- Agregar modo offline robusto
- Mejorar captura de evidencia

**NO incluir en mobile**:
- ❌ Gestión de usuarios
- ❌ Configuración del sistema
- ❌ Estadísticas avanzadas
- ❌ Exportación de reportes
- ❌ Dashboard de admin completo

---

## 🗂️ PRIORIDADES DE DESARROLLO

### Fase 1 - Backend API (COMPLETADO ✅)
- ✅ Sistema de autenticación
- ✅ CRUD de usuarios
- ✅ CRUD de denuncias (reports)
- ✅ CRUD de infracciones
- ✅ CRUD de partes (citations)
- ✅ CRUD de fichas médicas
- ✅ CRUD de vehículos
- ✅ Sistema de notificaciones

### Fase 2 - Web Admin (EN CURSO 🔄)
1. **Dashboard principal con estadísticas**
2. **Gestión completa de usuarios**
3. **Gestión de denuncias con asignación**
4. **Gestión de infracciones**
5. **Sistema de reportes**
6. **Configuración del sistema**

### Fase 3 - Mobile App (PENDIENTE ⏳)
1. **Actualizar dependencias Flutter**
2. **Adaptar a nueva API**
3. **Implementar nuevos endpoints**
4. **Completar módulo de consultas**
5. **Mejorar UX/UI**
6. **Tests y optimización**

---

## 📝 CONCLUSIONES

### Fortalezas de la App Flutter:
✅ **Arquitectura limpia** y bien estructurada
✅ **Separación de responsabilidades** clara
✅ **Patrón BLoC** implementado correctamente
✅ **Código reutilizable** y mantenible
✅ **Manejo robusto de estados**
✅ **Integración completa con Firebase**
✅ **UX fluida** con animaciones
✅ **Soporte multi-rol** bien diseñado

### Áreas de Mejora:
⚠️ Dependencias desactualizadas
⚠️ Falta de tests
⚠️ Modo offline limitado
⚠️ Algunos módulos incompletos (vehículos, consultas)
⚠️ Funcionalidades de admin que deberían estar en web

### Estrategia Recomendada:
1. **Migrar TODO admin a web** → La web debe ser la herramienta principal de administración
2. **Mobile solo para campo** → Ciudadanos e inspectores usan mobile
3. **Sincronizar modelos** → Los modelos de datos deben ser idénticos entre backend, web y mobile
4. **API REST unificada** → Una sola API sirve a web y mobile
5. **Notificaciones push** → Mantener FCM para mobile, considerar web push para admin

---

## 📊 ESTADÍSTICAS DEL CÓDIGO

- **Total de archivos Dart**: 147
- **Pantallas**: ~15
- **BLoCs**: ~8
- **Casos de uso**: ~25
- **Servicios**: 6
- **Widgets personalizados**: ~10
- **Modelos de datos**: ~15

---

**Documento creado por**: Claude Code
**Para**: Proyecto FROGIO - Santa Juana
**Propósito**: Análisis completo de la app Flutter original para guiar el desarrollo del nuevo sistema web/mobile
