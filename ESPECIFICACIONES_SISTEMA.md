# 🚨 FROGIO - Sistema de Gestión de Seguridad Pública Municipal
## Especificaciones Técnicas Completas - Santa Juana

**Versión**: 2.0
**Fecha**: Diciembre 2025
**Cliente**: Municipalidad de Santa Juana

---

## 🎯 OBJETIVO PRINCIPAL

**"Sistema integral para salvar vidas y mejorar la seguridad pública municipal"**

El sistema debe permitir:
1. **Respuesta rápida a emergencias** mediante botón de pánico
2. **Gestión eficiente de denuncias** ciudadanas con seguimiento en tiempo real
3. **Control y trazabilidad** de infracciones y citaciones con historial
4. **Coordinación efectiva** entre ciudadanos, inspectores y administradores

---

## 👥 ROLES Y PERMISOS

### 1. CIUDADANO (Mobile App)
**Objetivo**: Reportar problemas y emergencias, acceder a servicios municipales

**Funcionalidades**:
- ✅ Crear cuenta y perfil
- ✅ Gestionar información personal (nombre, RUT, teléfono, dirección)
- ✅ Agregar información médica (grupo sanguíneo, alergias, condiciones, medicamentos)
- ✅ Agregar información familiar (contactos de emergencia)
- ✅ Crear denuncias con fotos y geolocalización
- ✅ Ver historial de denuncias propias
- ✅ Recibir notificaciones de cambios de estado
- 🆕 **BOTÓN DE PÁNICO** con geolocalización automática
- 🆕 Subir foto de perfil

### 2. INSPECTOR (Mobile App)
**Objetivo**: Atender denuncias, registrar infracciones, gestionar operativo diario

**Funcionalidades**:
- ✅ Ver denuncias asignadas
- ✅ Actualizar estado de denuncias
- ✅ Crear infracciones con evidencia fotográfica
- ✅ Crear citaciones/partes
- ✅ Registrar vehículos infractores
- 🆕 **BITÁCORA DE VIAJE**:
  - Seleccionar vehículo municipal
  - Registrar kilómetros inicio/fin
  - Registrar personal que asiste
  - Hora inicio/fin del turno
  - Ruta recorrida (opcional)
- 🆕 **BÚSQUEDA DE HISTORIAL**:
  - Por patente de vehículo
  - Por RUT de persona
  - Por dirección
  - Mostrar todas las multas/citaciones anteriores
- 🆕 **RECIBIR ALERTAS DE PÁNICO** con prioridad alta y sonido insistente
- 🆕 Consultar fichas médicas al atender emergencias

### 3. ADMINISTRADOR (Web App)
**Objetivo**: Supervisión general, reportería, gestión de usuarios

**Funcionalidades**:
- ✅ Dashboard con estadísticas en tiempo real
- ✅ Gestión completa de usuarios (CRUD)
- ✅ Ver todas las denuncias del sistema
- ✅ Asignar denuncias a inspectores
- ✅ Ver infracciones y citaciones
- ✅ Gestión de vehículos municipales
- 🆕 **GENERACIÓN DE REPORTES**:
  - Exportar a PDF
  - Exportar a Excel (.xlsx)
  - Filtros por fecha, tipo, estado, inspector
  - Reportes de:
    * Denuncias por período
    * Infracciones por período
    * Bitácoras de viaje
    * Estadísticas de rendimiento
    * Tiempos de respuesta
- 🆕 **ALERTAS AUTOMÁTICAS**:
  - Denuncias no atendidas en 24h
  - Denuncias no asignadas
  - Botones de pánico sin respuesta
  - Bitácoras incompletas
- 🆕 **BÚSQUEDA AVANZADA** de todo el historial

---

## 📱 APP MOBILE - ESPECIFICACIONES DETALLADAS

### MÓDULO 1: AUTENTICACIÓN Y PERFIL

#### Registro de Usuario
```
Campos obligatorios:
- Email
- Contraseña (8+ caracteres, mayúsculas, números)
- RUT (validación formato chileno)
- Nombre completo
- Rol (ciudadano por defecto, inspector/admin asignado por admin)

Campos opcionales (completar después):
- Teléfono
- Dirección completa
- Foto de perfil
```

#### Perfil Completo
```
Información Personal:
- Nombre, RUT, Email
- Teléfono principal
- Dirección (calle, número, villa/sector, ciudad)
- Foto de perfil (subida a MinIO)

Información Médica (solo para emergencias):
- Grupo sanguíneo
- Alergias conocidas
- Condiciones médicas crónicas
- Medicamentos que toma
- Previsión de salud
- N° afiliado

Contactos de Emergencia:
- Nombre contacto 1
- Teléfono contacto 1
- Relación (esposo/a, hijo/a, padre/madre, etc.)
- Nombre contacto 2
- Teléfono contacto 2
- Relación
```

### MÓDULO 2: DENUNCIAS (Para Ciudadanos)

#### Crear Denuncia
```
Datos de la Denuncia:
- Título (máx 100 caracteres)
- Descripción detallada
- Categoría:
  * Alumbrado público
  * Basura/Aseo
  * Veredas/Calles
  * Áreas verdes
  * Ruidos molestos
  * Animales callejeros
  * Otros

- Ubicación (3 métodos):
  1. GPS automático (ubicación actual)
  2. Seleccionar en mapa
  3. Escribir dirección manualmente

- Evidencia:
  * Hasta 5 fotos
  * Opción de captura directa con cámara

- Prioridad (asignada automáticamente, puede ser modificada por admin):
  * Baja
  * Media
  * Alta
  * Urgente

Estados de la denuncia:
1. Pendiente (recién creada)
2. Asignada (inspector asignado)
3. En revisión (inspector revisando)
4. En proceso (inspector trabajando en solución)
5. Resuelta (problema solucionado)
6. Rechazada (no procede)
7. Archivada
```

#### Ver Mis Denuncias
```
Lista con filtros:
- Todas
- Pendientes
- En proceso
- Resueltas
- Rechazadas

Cada item muestra:
- Título
- Estado con color
- Fecha de creación
- Inspector asignado (si aplica)
- Última actualización

Detalle de denuncia:
- Todos los datos ingresados
- Fotos adjuntas
- Ubicación en mapa
- Historial de cambios de estado
- Respuestas del inspector/admin
- Fotos de resolución (si las hay)
```

### MÓDULO 3: BOTÓN DE PÁNICO 🚨

```
Ubicación: Pantalla principal, siempre visible

Funcionamiento:
1. Usuario presiona botón de pánico
2. Sistema captura automáticamente:
   - Ubicación GPS exacta
   - Timestamp
   - Datos del usuario
   - Información médica
   - Contactos de emergencia
   - Foto de perfil

3. Sistema envía notificación PUSH a:
   - TODOS los inspectores activos
   - TODOS los administradores

4. Notificación tiene:
   - Sonido insistente (no se puede silenciar fácilmente)
   - Vibración
   - Prioridad MÁXIMA
   - Aparece en pantalla bloqueada

5. Inspectores ven:
   - Mapa con ubicación exacta
   - Nombre y foto del usuario
   - Teléfono para llamar directamente
   - Información médica relevante
   - Botón "Atendiendo" para tomar la emergencia

6. Sistema registra:
   - Hora de activación del pánico
   - Hora de respuesta del inspector
   - Inspector que atendió
   - Tiempo total de respuesta
   - Resolución/cierre

Confirmación:
- Doble tap para evitar activaciones accidentales
- Mensaje: "¿Estás en una emergencia real?"
- Botones: "Sí, necesito ayuda" / "Cancelar"
```

### MÓDULO 4: INFRACCIONES (Para Inspectores)

```
Crear Infracción:
- Tipo de infracción
- Artículo/ordenanza municipal que transgrede
- Datos del infractor:
  * Nombre completo
  * RUT
  * Dirección
  * Teléfono (opcional)

- Ubicación GPS automática
- Fotos de evidencia (hasta 10)
- Descripción de los hechos
- Firma digital del inspector
- Firma digital del infractor (opcional, si se niega se registra)

Estados:
1. Creada
2. Notificada
3. Apelada
4. Confirmada
5. Pagada
6. Cancelada
```

### MÓDULO 5: CITACIONES/PARTES (Para Inspectores)

```
Crear Citación:
- Tipo (tránsito, municipal, sanitaria, etc.)
- Artículo que transgrede
- Vehículo (si aplica):
  * Patente
  * Marca
  * Modelo
  * Color
  * Año (opcional)

- Persona responsable:
  * Nombre
  * RUT
  * Licencia de conducir (si aplica)

- Monto de la multa
- Ubicación GPS
- Fotos de evidencia
- Descripción
- Firma digital

Historial de Vehículo:
Al ingresar patente, mostrar:
- Todas las multas anteriores
- Fechas
- Tipos de infracciones
- Estados (pagada, pendiente, apelada)
- Total acumulado

Historial de Persona:
Al ingresar RUT, mostrar:
- Todas las multas/citaciones
- Infracciones municipales
- Denuncias realizadas (si es ciudadano)
```

### MÓDULO 6: BITÁCORA DE VIAJE (Para Inspectores)

```
Iniciar Turno:
- Fecha y hora automática
- Seleccionar vehículo municipal de lista
- Kilometraje inicial (obligatorio)
- Personal que asiste:
  * Inspector principal (automático)
  * Agregar otros funcionarios (opcional)
  * Nombre y RUT de cada uno

Durante el turno:
- Sistema registra rutas (opcional, con GPS)
- Permite agregar notas/observaciones
- Vincular denuncias/infracciones atendidas

Finalizar Turno:
- Hora de fin (automática)
- Kilometraje final (obligatorio)
- Kilómetros recorridos (calculado)
- Resumen de actividades:
  * N° denuncias atendidas
  * N° infracciones creadas
  * N° citaciones emitidas
  * N° emergencias atendidas

- Novedades/observaciones del turno
- Firma digital

Reportes de Bitácora:
- Admin puede ver todas las bitácoras
- Filtrar por vehículo, inspector, fecha
- Exportar a Excel
- Calcular rendimiento (km/actividad)
```

---

## 🌐 WEB ADMIN - ESPECIFICACIONES DETALLADAS

### DASHBOARD (Ya implementado ✅)
```
Estadísticas en tiempo real:
- Total de denuncias
- Denuncias pendientes
- Denuncias resueltas
- Total de infracciones
- Total de usuarios
- Usuarios activos
- Total de vehículos

Gráficos (pendiente):
- Denuncias por categoría (pie chart)
- Denuncias por mes (line chart)
- Tiempo promedio de resolución
- Infracciones por tipo
```

### GESTIÓN DE USUARIOS

```
Lista de Usuarios:
- Tabla con:
  * Foto de perfil
  * Nombre
  * Email
  * RUT
  * Rol
  * Estado (activo/inactivo)
  * Fecha de registro
  * Acciones (editar, activar/desactivar)

Filtros:
- Por rol (todos, ciudadano, inspector, admin)
- Por estado (todos, activos, inactivos)
- Búsqueda por nombre/email/RUT

Crear/Editar Usuario:
- Todos los campos de perfil
- Asignar rol
- Activar/desactivar
- Resetear contraseña

Perfil de Usuario (detalle):
- Información completa
- Historial de denuncias
- Historial de infracciones (si es inspector)
- Bitácoras de viaje (si es inspector)
- Información médica (solo visible en emergencias)
```

### GESTIÓN DE DENUNCIAS

```
Lista de Denuncias:
- Tabla con:
  * ID
  * Título
  * Categoría
  * Estado con color
  * Prioridad con color
  * Ciudadano
  * Inspector asignado
  * Fecha creación
  * Tiempo transcurrido
  * Acciones

Filtros avanzados:
- Por estado
- Por prioridad
- Por categoría
- Por inspector
- Por rango de fechas
- Por ubicación (sector)
- Sin asignar
- No atendidas en 24h

Detalle de Denuncia:
- Toda la información
- Fotos en galería
- Mapa con ubicación
- Datos del ciudadano
- Asignar/reasignar inspector
- Cambiar estado
- Cambiar prioridad
- Agregar respuesta
- Subir fotos de resolución
- Historial completo de cambios
- Tiempo de respuesta

Acciones masivas:
- Asignar múltiples denuncias a un inspector
- Cambiar estado de varias denuncias
- Exportar selección a Excel
```

### GESTIÓN DE INFRACCIONES Y CITACIONES

```
Lista combinada:
- Infracciones municipales
- Citaciones de tránsito
- Partes sanitarios

Tabla con:
- Tipo
- N° de parte
- Infractor (nombre, RUT)
- Vehículo (si aplica)
- Inspector
- Monto
- Estado
- Fecha
- Acciones

Filtros:
- Por tipo
- Por estado (pendiente, pagada, apelada, cancelada)
- Por inspector
- Por rango de fechas
- Por monto
- Por RUT del infractor
- Por patente del vehículo

Búsqueda de Historial:
Campo de búsqueda que acepta:
- RUT → Muestra todas las multas de esa persona
- Patente → Muestra todas las multas de ese vehículo
- Dirección → Muestra todas las infracciones en esa ubicación

Detalle de Infracción:
- Todos los datos
- Fotos de evidencia
- Mapa de ubicación
- Datos del infractor
- Datos del vehículo (si aplica)
- Artículo infringido
- Firmas digitales
- Historial de estados
- Opción de anular (solo admin)
```

### GENERACIÓN DE REPORTES 📊

```
Tipos de Reportes:

1. Reporte de Denuncias:
   Filtros:
   - Rango de fechas
   - Estado
   - Categoría
   - Inspector
   - Sector/zona

   Incluye:
   - Resumen ejecutivo
   - Tabla detallada
   - Gráficos:
     * Por categoría
     * Por estado
     * Por inspector
     * Por zona
   - Tiempos promedio de respuesta
   - Denuncias más antiguas sin resolver

   Formatos: PDF, Excel

2. Reporte de Infracciones:
   Filtros:
   - Rango de fechas
   - Tipo
   - Inspector
   - Estado de pago

   Incluye:
   - Resumen ejecutivo
   - Tabla detallada
   - Monto total recaudado
   - Monto pendiente
   - Gráficos por tipo
   - Top infractores

   Formatos: PDF, Excel

3. Reporte de Bitácoras:
   Filtros:
   - Rango de fechas
   - Vehículo
   - Inspector

   Incluye:
   - Tabla de turnos
   - Kilómetros totales por vehículo
   - Actividades por inspector
   - Rendimiento (actividades/km)
   - Costos estimados (combustible)

   Formatos: PDF, Excel

4. Reporte Estadístico General:
   Período: mes, trimestre, año

   Incluye:
   - Dashboard completo
   - Todos los gráficos
   - Comparativa con período anterior
   - Tendencias
   - KPIs principales

   Formato: PDF

Programación de Reportes:
- Configurar reportes automáticos
- Frecuencia (diario, semanal, mensual)
- Enviar por email a destinatarios
```

### SISTEMA DE ALERTAS 🔔

```
Alertas Automáticas:

1. Denuncias no atendidas:
   - Si una denuncia lleva 24h sin asignar
   - Si una denuncia lleva 48h sin respuesta
   - Si una denuncia lleva 7 días en proceso

   Acción:
   - Notificación al admin
   - Email al admin
   - Aparece en panel de alertas

2. Botones de pánico:
   - Si se activa un botón de pánico
   - Si ningún inspector responde en 5 min

   Acción:
   - Notificación PUSH a todos los admins
   - Email urgente
   - SMS al jefe de operaciones

3. Bitácoras incompletas:
   - Si un inspector no cerró su bitácora
   - Si faltan datos obligatorios

   Acción:
   - Notificación al inspector
   - Recordatorio después de 1 hora
   - Alerta al admin después de 24h

4. Infracciones apeladas:
   - Nueva apelación ingresada

   Acción:
   - Notificación al admin
   - Email al departamento jurídico

Panel de Alertas:
- Lista de todas las alertas pendientes
- Filtros por tipo y prioridad
- Marcar como atendida
- Asignar a usuario
- Ver historial de alertas
```

---

## 🔧 ESPECIFICACIONES TÉCNICAS

### STACK TECNOLÓGICO

```
Backend:
✅ Node.js 22
✅ Express.js
✅ TypeScript
✅ PostgreSQL 16
✅ Prisma ORM
✅ JWT Authentication
✅ Bcrypt para contraseñas
✅ Socket.io (para tiempo real - pendiente implementar)
⚠️ MinIO (para archivos - pendiente configurar)
⚠️ Bull/Redis (para colas - opcional)

Web Admin:
✅ Next.js 14 (App Router)
✅ React 18
✅ TypeScript
✅ Tailwind CSS
✅ Heroicons
✅ @tailwindcss/forms
⚠️ Chart.js o Recharts (para gráficos - pendiente)
⚠️ jsPDF (para reportes PDF - pendiente)
⚠️ xlsx (para Excel - pendiente)

Mobile App:
✅ Flutter 3.35+
✅ Dart
✅ BLoC Pattern
✅ Clean Architecture
❌ Firebase (eliminar - migrar a backend propio)
✅ Google Maps / Mapbox
✅ Image Picker
✅ Geolocator
⚠️ Flutter Local Notifications
⚠️ Firebase Messaging (mantener solo para push)

Base de Datos:
✅ PostgreSQL 16
✅ Multi-tenancy (schema por municipalidad)
✅ Tablas implementadas:
   - users
   - reports
   - infractions
   - citations
   - vehicles
   - medical_records
   - notifications

🆕 Pendientes:
   - trip_logs (bitácoras)
   - panic_alerts (botones de pánico)
   - report_history (historial de cambios)
   - system_alerts (alertas del sistema)
```

### ARQUITECTURA

```
┌─────────────────┐
│   Mobile App    │
│   (Flutter)     │
└────────┬────────┘
         │
         │ HTTP/REST + WebSocket
         │
┌────────▼────────┐
│   Web Admin     │
│   (Next.js)     │
└────────┬────────┘
         │
         │ HTTP/REST + WebSocket
         │
┌────────▼────────────────────────┐
│      Backend API (Node.js)      │
│  ┌──────────────────────────┐  │
│  │  Authentication (JWT)     │  │
│  ├──────────────────────────┤  │
│  │  Users Management         │  │
│  │  Reports Management       │  │
│  │  Infractions Management   │  │
│  │  Notifications (Socket)   │  │
│  │  Files (MinIO)            │  │
│  │  Reports Generator        │  │
│  └──────────────────────────┘  │
└────────┬────────────────────────┘
         │
         │ Prisma ORM
         │
┌────────▼────────┐
│   PostgreSQL    │
│   (Multi-tenant)│
└─────────────────┘

External Services:
┌─────────────────┐
│  Firebase FCM   │ → Push Notifications
│  (solo push)    │
└─────────────────┘

┌─────────────────┐
│     MinIO       │ → File Storage
│  (self-hosted)  │
└─────────────────┘
```

---

## 🚀 PLAN DE IMPLEMENTACIÓN

### FASE 1: Completar Web Admin (2 semanas)
- [ ] CRUD completo de usuarios
- [ ] CRUD completo de denuncias con asignación
- [ ] Gestión de infracciones y citaciones
- [ ] Sistema de búsqueda de historial
- [ ] Implementar WebSockets para tiempo real

### FASE 2: Reportería y Alertas (1 semana)
- [ ] Generación de PDF con jsPDF
- [ ] Generación de Excel con xlsx
- [ ] Sistema de alertas automáticas
- [ ] Notificaciones en tiempo real

### FASE 3: Migrar App Mobile (2 semanas)
- [ ] Eliminar Firebase Auth → JWT con backend
- [ ] Eliminar Firestore → PostgreSQL via API
- [ ] Migrar Storage → MinIO
- [ ] Mantener FCM solo para push notifications
- [ ] Implementar nuevos endpoints

### FASE 4: Nuevas Funcionalidades Mobile (2 semanas)
- [ ] Botón de pánico con geolocalización
- [ ] Información médica en perfil
- [ ] Bitácora de viaje para inspectores
- [ ] Búsqueda de historial
- [ ] Notificaciones push mejoradas

### FASE 5: Testing y Deployment (1 semana)
- [ ] Tests unitarios backend
- [ ] Tests de integración
- [ ] Tests E2E mobile
- [ ] Deployment en servidor de producción
- [ ] Configuración de MinIO
- [ ] Configuración de FCM

---

## 📝 NOTAS IMPORTANTES

### Seguridad
- Todas las contraseñas con bcrypt (salt rounds: 10)
- JWT con expiración (15 min access, 7 días refresh)
- HTTPS obligatorio en producción
- Sanitización de inputs
- Rate limiting en API
- CORS configurado correctamente

### Performance
- Paginación en todas las listas
- Lazy loading de imágenes
- Compresión de imágenes antes de subir
- Índices en base de datos
- Caché de consultas frecuentes
- WebSocket para tiempo real (evitar polling)

### UX/UI
- Diseño responsive (mobile-first)
- Modo oscuro (opcional, fase posterior)
- Accesibilidad (WCAG 2.1 AA)
- Feedback visual en todas las acciones
- Loading states
- Error handling amigable
- Confirmaciones en acciones destructivas

### Datos Sensibles
- Información médica solo visible en emergencias
- Encriptación de datos sensibles en base de datos
- Logs de acceso a información médica
- GDPR compliance (aunque no aplica en Chile, buena práctica)
- Permitir a usuarios eliminar su cuenta

---

**Última actualización**: Diciembre 2025
**Próxima revisión**: Al completar cada fase
