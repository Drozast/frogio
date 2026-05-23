# Plan de Reestructuración - Perfil Inspector Frogio

> Documento generado: 2026-04-12
> Objetivo: Reestructurar completamente el perfil de inspector para que los flujos de denuncia, notificación/citación y fiscalización sean coherentes, trazables y funcionales.

---

## 1. CONTEXTO Y REGLAS DE NEGOCIO

### 1.1 Actores del Sistema
| Actor | Rol |
|-------|-----|
| **Ciudadano** | Crea denuncias (normales y SOS/pánico). Puede ver el estado y etapas de sus denuncias. |
| **Inspector** | Atiende denuncias de ciudadanos. Crea sus propias denuncias (registro de trabajo). Crea notificaciones/citaciones durante fiscalizaciones. |
| **Admin** | Gestión completa del sistema. |

### 1.2 Conceptos Clave (Definiciones de Negocio)

#### DENUNCIA (Report)
- Reporte de un problema creado por un **ciudadano** O por un **inspector**.
- Cuando la crea un ciudadano: es una queja que necesita atención.
- Cuando la crea un inspector: es un registro de trabajo de algo que encontró en terreno.
- Debe tener **trazabilidad completa** de etapas para que el ciudadano vea el progreso y el inspector lleve registro.

#### NOTIFICACIÓN / CITACIÓN (Citation)
- Documento que deja un inspector durante una **fiscalización**.
- **Advertencia**: Notificación de advertencia (papelito de aviso, sin consecuencia legal inmediata).
- **Citación**: Citación al Juzgado de Policía Local (consecuencia legal, debe comparecer).
- Se aplican a: personas, domicilios, vehículos, comercios.
- NO es lo mismo que una denuncia. La denuncia reporta un problema; la notificación/citación es una acción del inspector sobre un infractor.

#### INFRACCIÓN (Infraction) - ACTUALMENTE NO USADO EN MOBILE
- Multa económica. Tiene monto, método de pago, estado de pago.
- Existe en backend pero NO tiene UI en mobile.
- **Decisión requerida**: ¿Se implementa como feature separada o se fusiona con citaciones?

---

## 2. DIAGNÓSTICO: PROBLEMAS ENCONTRADOS

### 2.1 Problemas Críticos

#### P1: Inspector NO puede crear denuncias propias
- **Archivo**: `apps/mobile/lib/dashboard/presentation/pages/dashboard_screen.dart`
- **Problema**: El bottom nav del inspector tiene: Inicio, Mapa, Citaciones, Perfil. NO hay acceso a crear denuncias propias.
- **En reports screen** (`inspector_reports_screen.dart`): Solo lista denuncias de ciudadanos para atender. No tiene botón "Crear Denuncia".
- **Impacto**: El inspector no puede registrar su trabajo como denuncia propia.

#### P2: El inspector NO puede gestionar etapas de una denuncia
- **Archivo**: `inspector/presentation/pages/report_detail_screen.dart`
- **Problema**: El inspector solo puede CERRAR una denuncia (resolver/rechazar/duplicada). No puede:
  - Cambiar estado a "en proceso"
  - Agregar comentarios/notas de seguimiento intermedios
  - Registrar acciones realizadas (visitas, inspecciones, llamadas)
  - Adjuntar evidencia fotográfica de su gestión
- **Backend soporta**: El PATCH de reports acepta `status`, `resolution`, `changeReason`. Pero el mobile solo usa "cerrar".
- **Impacto**: El ciudadano no ve progreso. El inspector no tiene registro de gestión.

#### P3: Falta historial de etapas visible para el ciudadano
- **Archivo**: `citizen/presentation/pages/` - pantallas de detalle de reporte del ciudadano
- **Problema**: El backend genera `statusHistory` y `report_versions`, pero el mobile del ciudadano NO muestra una timeline de etapas.
- **Impacto**: El ciudadano no sabe qué está pasando con su denuncia.

#### P4: Navegación del inspector incompleta
- **Archivo**: `dashboard_screen.dart` líneas del inspector nav
- **Problema**: El bottom nav tiene solo 4 tabs (Inicio, Mapa, Citaciones, Perfil). Las denuncias solo se acceden desde el home screen como botón secundario.
- **Impacto**: Las denuncias son una función central del inspector pero están enterradas en navegación secundaria.

#### P5: Desconexión entre Citaciones y Denuncias
- **Problema**: Si un inspector atiende una denuncia y durante la gestión necesita crear una citación, no hay vínculo entre ambas.
- **Backend**: La tabla `court_citations` tiene campo `infraction_id` pero NO tiene `report_id`.
- **Impacto**: No hay trazabilidad entre "atendí esta denuncia" y "dejé esta citación como resultado".

#### P6: Schema de DB incompleto para citaciones
- **Archivo**: `apps/backend/prisma/migrations/001_initial_setup.sql`
- **Problema**: La tabla `court_citations` no tiene los campos que el código espera:
  - Faltan: `citation_type`, `target_type`, `target_name`, `target_rut`, `target_address`, `target_phone`, `target_plate`, `location_address`, `latitude`, `longitude`, `photos`, `issued_by`
- **Las tablas de versiones** (`report_versions`, `citation_versions`) no existen en migraciones.
- **Nota**: Es posible que se hayan agregado en migraciones posteriores no revisadas. Verificar en producción.

### 2.2 Problemas Medios

#### P7: Dos home screens del inspector
- **Archivos**: `inspector_home_screen.dart` (v1) y `inspector_home_screen_v2.dart` (v2)
- **Problema**: V1 existe pero no se usa. Código muerto.

#### P8: Auto-refresh excesivo
- Citations list: cada 3 segundos
- Reports list: cada 3 segundos  
- Map: cada 10 segundos
- Home: cada 10 segundos
- **Impacto**: Consumo de batería, tráfico de red innecesario.

#### P9: Mapeo de estados inconsistente mobile ↔ backend
- **Mobile report statuses**: `submitted`, `inProgress`, `resolved`, `rejected`, `duplicate`, `draft`, `reviewing`, `archived`, `cancelled`
- **Backend DB statuses**: `pendiente`, `en_proceso`, `resuelto`, `rechazado`
- El backend normaliza (`submitted` → `pendiente`, `resolved` → `resuelto`), pero el mobile maneja estados que no existen en DB.

#### P10: Infractions module tiene data/domain layer pero sin UI
- **Archivos**: `inspector/domain/entities/infraction_entity.dart`, `infraction_bloc.dart`, etc.
- **Problema**: Código de infracciones existe en mobile pero sin pantallas. Dead code parcial.

---

## 3. PLAN DE REESTRUCTURACIÓN

### Fase 1: Reestructurar la Navegación del Inspector
**Prioridad: ALTA | Esfuerzo: Medio**

#### Tarea 1.1: Rediseñar Bottom Navigation del Inspector
**Archivo a modificar**: `apps/mobile/lib/dashboard/presentation/pages/dashboard_screen.dart`

**Cambiar de:**
```
Tab 0: Inicio (InspectorHomeScreenV2)
Tab 1: Mapa (InspectorMapScreen)
Tab 2: Citaciones (CitationsMainScreen)
Tab 3: Perfil
```

**Cambiar a:**
```
Tab 0: Inicio (InspectorHomeScreenV2) - Dashboard resumen
Tab 1: Denuncias (InspectorReportsScreen) - Gestión de denuncias (ciudadanas + propias)
Tab 2: Fiscalización (CitationsMainScreen) - Citaciones y notificaciones
Tab 3: Mapa (InspectorMapScreen)
Tab 4: Perfil
```

**Justificación**: Las denuncias son el core del trabajo del inspector y merecen tab propio. El mapa es complementario.

#### Tarea 1.2: Actualizar Home Screen del Inspector
**Archivo a modificar**: `apps/mobile/lib/features/inspector/presentation/pages/inspector_home_screen_v2.dart`

**Cambios:**
1. Agregar stat card: "Denuncias Pendientes" (count de reports con status=pendiente asignados o sin asignar)
2. Agregar stat card: "Denuncias En Proceso" (count de reports con status=en_proceso asignados al inspector)
3. Mantener: "Citaciones de Hoy", "Citaciones Pendientes", "Alertas SOS"
4. Cambiar los action cards secundarios:
   - "Nueva Denuncia" (crear denuncia propia del inspector)
   - "Nueva Citación" (mantener)
   - "Mapa" (mantener)
5. Sección "Actividad Reciente": mostrar últimas 5 acciones del inspector (denuncias atendidas + citaciones creadas, mezcladas por fecha)

#### Tarea 1.3: Eliminar inspector_home_screen.dart (v1)
**Archivo a eliminar**: `apps/mobile/lib/features/inspector/presentation/pages/inspector_home_screen.dart`
- Buscar cualquier referencia y eliminar imports.

---

### Fase 2: Reestructurar Flujo de Denuncias del Inspector
**Prioridad: ALTA | Esfuerzo: Alto**

#### Tarea 2.1: Rediseñar Inspector Reports Screen con sub-tabs
**Archivo a modificar**: `apps/mobile/lib/features/inspector/presentation/pages/inspector_reports_screen.dart`

**Estructura nueva:**

```
InspectorReportsScreen
├── SegmentedControl: [Ciudadanas | Mis Denuncias]
│
├── Tab "Ciudadanas" (denuncias de ciudadanos para atender):
│   ├── Sub-tabs: Pendientes | En Proceso | Resueltas
│   ├── Filtro por categoría (mantener)
│   ├── Cada card muestra: título, categoría, prioridad, fecha, ubicación
│   ├── Badge de prioridad (urgente = rojo, alta = naranja)
│   └── TAP → ReportDetailScreen (con gestión de etapas)
│
├── Tab "Mis Denuncias" (denuncias propias del inspector):
│   ├── Sub-tabs: En Proceso | Resueltas
│   ├── Botón FAB: "Nueva Denuncia" (crear denuncia propia)
│   ├── Cada card muestra: título, categoría, fecha, estado
│   └── TAP → ReportDetailScreen (vista de su propia denuncia)
│
└── API calls:
    ├── Ciudadanas: GET /api/reports (sin filtro userId, filtro status)
    └── Mis Denuncias: GET /api/reports?userId={inspectorId}
```

**Lógica de filtrado en backend**: Ya soportado. El controller no filtra por userId si el role es inspector. Para "Mis Denuncias" se necesita agregar query param `createdBy` o `userId` opcional.

#### Tarea 2.2: Crear pantalla de creación de denuncia del inspector
**Archivo nuevo**: `apps/mobile/lib/features/inspector/presentation/pages/create_inspector_report_screen.dart`

**Reutilizar** la lógica de `enhanced_create_report_screen.dart` del ciudadano pero adaptada:

```
CreateInspectorReportScreen (formulario simplificado)
├── Título (required)
├── Categoría (dropdown: mismas categorías del ciudadano)
├── Descripción (required)
├── Ubicación:
│   ├── Botón "Usar GPS" (auto-detect)
│   ├── Botón "Buscar en Mapa"
│   └── Campo dirección manual
├── Prioridad (selector: baja/media/alta/urgente, default: media)
├── Fotos (max 5, cámara/galería)
├── Referencia (opcional: número de caso, dirección específica)
└── Botón "Crear Denuncia"
    └── POST /api/reports con user_id del inspector
```

**Diferencias con formulario ciudadano:**
- Sin stepper (formulario directo en scroll, más rápido para trabajo en terreno)
- Prioridad editable (el inspector puede asignar prioridad directamente)
- GPS auto-activado al abrir (el inspector está en terreno)

#### Tarea 2.3: Rediseñar Report Detail Screen con gestión de etapas
**Archivo a modificar**: `apps/mobile/lib/features/inspector/presentation/pages/report_detail_screen.dart`

**Estructura nueva:**

```
ReportDetailScreen
├── Header:
│   ├── Título + Categoría badge
│   ├── Estado actual (chip colored)
│   ├── Prioridad badge
│   ├── Fecha de creación
│   └── Ciudadano que denunció (si es denuncia ciudadana)
│
├── Sección "Detalle":
│   ├── Descripción completa
│   ├── Ubicación con mini-mapa (tappable para abrir mapa grande)
│   ├── Galería de fotos del denunciante (horizontal scroll)
│   └── Referencias adicionales
│
├── Sección "Historial de Etapas" (NUEVA - timeline vertical):
│   ├── Cada etapa muestra:
│   │   ├── Icono de estado (circle con color)
│   │   ├── Estado: "Pendiente" / "En Proceso" / "Resuelto" / "Rechazado"
│   │   ├── Fecha y hora
│   │   ├── Quién hizo el cambio (nombre del inspector/sistema)
│   │   ├── Comentario/razón del cambio
│   │   └── Fotos adjuntas en esa etapa (si hay)
│   └── Fuente: GET /api/reports/{id}/versions → mapear a timeline
│
├── Sección "Acciones del Inspector" (NUEVA - solo si estado != resuelto/rechazado):
│   │
│   ├── Botón "Tomar Denuncia" (solo si status=pendiente y no asignada):
│   │   └── PATCH /api/reports/{id} { status: 'en_proceso', assignedTo: inspectorId, changeReason: 'Inspector tomó la denuncia' }
│   │
│   ├── Botón "Agregar Seguimiento" (solo si status=en_proceso):
│   │   └── Abre modal con:
│   │       ├── Campo de texto: "Descripción de la acción realizada" (required)
│   │       ├── Selector de fotos (evidencia de la gestión, max 3)
│   │       └── Botón "Registrar"
│   │       └── PATCH /api/reports/{id} { changeReason: 'texto del seguimiento' }
│   │       NOTA: Esto requiere que el backend guarde el changeReason en report_versions
│   │       sin necesariamente cambiar el status. Ver Tarea 4.1.
│   │
│   ├── Botón "Crear Citación Vinculada" (NUEVO):
│   │   └── Navega a CreateCitationScreen con reportId pre-cargado
│   │   └── La citación se vincula a esta denuncia (ver Tarea 4.2)
│   │
│   ├── Botón "Cerrar Denuncia":
│   │   └── Abre modal con:
│   │       ├── Tipo de resolución: Resuelta / Rechazada / Duplicada (mantener actual)
│   │       ├── Comentario de resolución (required, min 10 chars)
│   │       ├── Fotos de evidencia de resolución (opcional)
│   │       └── PATCH /api/reports/{id} { status: 'resuelto'|'rechazado', resolution: 'texto', changeReason: 'texto' }
│   │
│   └── Sección "Citaciones Vinculadas" (NUEVA):
│       └── Lista de citaciones creadas como resultado de esta denuncia
│       └── Fuente: GET /api/citations?reportId={reportId}
│
└── Footer: Fecha última actualización
```

---

### Fase 3: Reestructurar Flujo de Citaciones/Notificaciones
**Prioridad: ALTA | Esfuerzo: Medio**

#### Tarea 3.1: Mejorar Citations List Screen
**Archivo a modificar**: `apps/mobile/lib/features/inspector/presentation/pages/citations_list_screen.dart`

**Cambios:**
1. Agregar filtro por tipo (advertencia vs citación) además de filtro por estado
2. En el detalle inline de cada citación, mostrar:
   - Si está vinculada a una denuncia: link clickable "Ver Denuncia #XXX"
   - Historial de cambios de estado (timeline mini, desde citation_versions)
3. Agregar acciones rápidas en cada card (swipe o long-press):
   - "Marcar como Notificado"
   - "Marcar como Asistió"
   - "Marcar como No Asistió"
4. Reducir auto-refresh de 3s a 30s (o usar pull-to-refresh manual)

#### Tarea 3.2: Mejorar Create Citation Screen
**Archivo a modificar**: `apps/mobile/lib/features/inspector/presentation/pages/create_citation_screen.dart`

**Cambios:**
1. Agregar campo opcional `reportId` (cuando se crea desde una denuncia, viene pre-cargado)
2. Agregar campo "Fecha de audiencia" (DatePicker) cuando tipo = citación
3. Agregar campo "Juzgado" (dropdown o text) cuando tipo = citación
4. Mejorar validación de RUT (formato chileno)
5. Al enviar, si tiene reportId, registrar la vinculación

#### Tarea 3.3: Crear Citation Detail Screen (pantalla dedicada)
**Archivo nuevo**: `apps/mobile/lib/features/inspector/presentation/pages/citation_detail_screen.dart`

Actualmente el detalle se muestra inline en un bottom sheet. Crear pantalla dedicada:

```
CitationDetailScreen
├── Header:
│   ├── Número de citación
│   ├── Tipo badge (Advertencia / Citación)
│   ├── Estado badge (colored)
│   └── Fecha de creación
│
├── Sección "Datos del Fiscalizado":
│   ├── Nombre
│   ├── RUT (si persona)
│   ├── Patente (si vehículo)
│   ├── Dirección del objetivo
│   └── Teléfono
│
├── Sección "Ubicación":
│   ├── Dirección de la fiscalización
│   ├── Mini-mapa con pin
│   └── Coordenadas
│
├── Sección "Detalle":
│   ├── Motivo
│   ├── Notas adicionales
│   └── Fotos/evidencia (galería)
│
├── Sección "Datos de Audiencia" (solo si tipo=citación):
│   ├── Juzgado
│   ├── Fecha de audiencia
│   └── Dirección del juzgado
│
├── Sección "Historial de Estados" (timeline):
│   └── Fuente: GET /api/citations/{id}/versions
│
├── Sección "Denuncia Vinculada" (si tiene reportId):
│   └── Card con resumen de la denuncia, tappable
│
└── Acciones:
    ├── Cambiar Estado (dropdown → PATCH)
    ├── Agregar Nota (text field → PATCH con changeReason)
    └── Agregar Fotos (append to photos array)
```

---

### Fase 4: Cambios en Backend
**Prioridad: ALTA | Esfuerzo: Medio**

#### Tarea 4.1: Endpoint para agregar seguimiento sin cambiar estado
**Archivo a modificar**: `apps/backend/src/modules/reports/reports.service.ts`

**Problema**: Actualmente el PATCH requiere cambiar algún campo para crear una versión. Se necesita poder agregar un "seguimiento" (nota + fotos) sin cambiar el estado.

**Solución**: Crear endpoint nuevo o modificar PATCH para aceptar solo `changeReason` + `attachments` sin cambios de status:

```
POST /api/reports/:id/follow-up
Body: {
  comment: string (required),
  attachments: string[] (photo URLs, optional)
}
Response: { success: true, version: number }
```

**Implementación:**
1. Crear nueva ruta en `reports.routes.ts`: `router.post('/:id/follow-up', roleGuard('inspector', 'admin'), ...)`
2. En service: insertar en `report_versions` con mismo status actual, el comment como `change_reason`, y adjuntos en un campo nuevo `attachments` (JSONB)
3. Actualizar `updated_at` del report principal

#### Tarea 4.2: Agregar campo report_id a citaciones
**Archivo a modificar**: Migration SQL nueva

```sql
ALTER TABLE santa_juana.court_citations 
ADD COLUMN report_id UUID REFERENCES santa_juana.reports(id) ON DELETE SET NULL;

CREATE INDEX idx_citations_report_id ON santa_juana.court_citations(report_id);
```

**Archivos a modificar en backend:**
- `apps/backend/src/modules/citations/citations.service.ts`: Agregar `reportId` a create y find queries
- `apps/backend/src/modules/citations/citations.types.ts`: Agregar `reportId` a DTOs

**Archivos a modificar en mobile:**
- `apps/mobile/lib/features/inspector/domain/entities/citation_entity.dart`: Agregar `reportId`
- `apps/mobile/lib/features/inspector/data/models/citation_model.dart`: Agregar serialización
- `apps/mobile/lib/features/inspector/data/datasources/citation_api_data_source.dart`: Enviar reportId en create

#### Tarea 4.3: Agregar attachments a report_versions
**Archivo a modificar**: Migration SQL nueva

```sql
ALTER TABLE santa_juana.report_versions
ADD COLUMN attachments JSONB DEFAULT '[]';
```

#### Tarea 4.4: Verificar/crear tablas de versiones
Verificar si `report_versions` y `citation_versions` existen en producción. Si no, crear migración:

```sql
CREATE TABLE IF NOT EXISTS santa_juana.report_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES santa_juana.reports(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    title VARCHAR(255),
    description TEXT,
    type VARCHAR(50),
    status VARCHAR(20),
    priority VARCHAR(20),
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    assigned_to UUID REFERENCES santa_juana.users(id),
    resolution TEXT,
    attachments JSONB DEFAULT '[]',
    modified_by UUID NOT NULL REFERENCES santa_juana.users(id),
    modified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    change_reason TEXT,
    UNIQUE(report_id, version_number)
);

CREATE TABLE IF NOT EXISTS santa_juana.citation_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    citation_id UUID NOT NULL REFERENCES santa_juana.court_citations(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    citation_type VARCHAR(20),
    target_type VARCHAR(20),
    target_name VARCHAR(255),
    target_rut VARCHAR(20),
    target_address TEXT,
    target_phone VARCHAR(20),
    target_plate VARCHAR(20),
    location_address TEXT,
    status VARCHAR(20),
    notes TEXT,
    notification_method VARCHAR(50),
    modified_by UUID NOT NULL REFERENCES santa_juana.users(id),
    modified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    change_reason TEXT,
    UNIQUE(citation_id, version_number)
);
```

#### Tarea 4.5: Verificar columnas faltantes en court_citations
Verificar si los campos de target/location existen en producción. Si no, crear migración:

```sql
-- Solo agregar las columnas que NO existen
ALTER TABLE santa_juana.court_citations
ADD COLUMN IF NOT EXISTS citation_type VARCHAR(20) DEFAULT 'citacion' CHECK (citation_type IN ('advertencia', 'citacion')),
ADD COLUMN IF NOT EXISTS target_type VARCHAR(20) DEFAULT 'persona' CHECK (target_type IN ('persona', 'domicilio', 'vehiculo', 'comercio', 'otro')),
ADD COLUMN IF NOT EXISTS target_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS target_rut VARCHAR(20),
ADD COLUMN IF NOT EXISTS target_address TEXT,
ADD COLUMN IF NOT EXISTS target_phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS target_plate VARCHAR(20),
ADD COLUMN IF NOT EXISTS location_address TEXT,
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS photos JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS issued_by UUID REFERENCES santa_juana.users(id),
ADD COLUMN IF NOT EXISTS report_id UUID REFERENCES santa_juana.reports(id) ON DELETE SET NULL;

-- Hacer court_name y address nullable (ya no son required en nuevo flujo)
ALTER TABLE santa_juana.court_citations ALTER COLUMN court_name DROP NOT NULL;
ALTER TABLE santa_juana.court_citations ALTER COLUMN hearing_date DROP NOT NULL;
ALTER TABLE santa_juana.court_citations ALTER COLUMN address DROP NOT NULL;
```

#### Tarea 4.6: Agregar endpoint para obtener citaciones por reporte
**Archivo a modificar**: `apps/backend/src/modules/citations/citations.routes.ts`

```
GET /api/citations?reportId={reportId}
```

Agregar filtro por `report_id` en el `findAll` del service.

#### Tarea 4.7: Agregar filtro createdBy para reports del inspector
**Archivo a modificar**: `apps/backend/src/modules/reports/reports.service.ts`

Permitir que el inspector filtre `GET /api/reports?createdBy={inspectorId}` para ver solo sus propias denuncias.

---

### Fase 5: Reestructurar Vista del Ciudadano (Trazabilidad)
**Prioridad: ALTA | Esfuerzo: Medio**

#### Tarea 5.1: Agregar Timeline de Etapas al Detalle de Denuncia del Ciudadano
**Archivo a identificar y modificar**: Pantalla de detalle de reporte del ciudadano (buscar en `features/citizen/presentation/pages/`)

**Agregar sección "Seguimiento de tu Denuncia":**

```
TimelineWidget
├── Cada etapa:
│   ├── Icono circular con color del estado
│   ├── Título: "Denuncia Creada" / "En Revisión" / "Inspector Asignado" / "Seguimiento" / "Resuelta"
│   ├── Fecha y hora
│   ├── Descripción: el change_reason de la versión
│   ├── Fotos adjuntas (si hay attachments en esa versión)
│   └── Línea conectora vertical al siguiente paso
│
├── Estado actual resaltado (borde más grueso, color primario)
│
└── Si está resuelta:
    └── Mostrar resolución final con ícono de check
```

**Fuente de datos**: `GET /api/reports/{id}` ya devuelve `statusHistory`. Complementar con `GET /api/reports/{id}/versions` para datos completos.

#### Tarea 5.2: Notificaciones push al ciudadano por cambio de estado
**Archivo a modificar**: `apps/backend/src/services/alerts.service.ts`

Verificar que `onReportStatusChange()` envía push notification al ciudadano. Si no:
1. En el handler de status change, obtener el `userId` (ciudadano) del report
2. Enviar push via Firebase: "Tu denuncia '{title}' cambió a estado: {nuevo_estado}"
3. Incluir el `changeReason` en el body de la notificación

---

### Fase 6: Normalización de Estados Mobile ↔ Backend
**Prioridad: MEDIA | Esfuerzo: Bajo**

#### Tarea 6.1: Unificar estados en mobile
**Archivos a modificar**:
- `apps/mobile/lib/features/citizen/domain/entities/enhanced_report_entity.dart`
- `apps/mobile/lib/features/inspector/presentation/pages/inspector_reports_screen.dart`

**Mapeo definitivo:**

| Estado Mobile (usar) | Estado Backend DB | Descripción |
|----|----|----|
| `pendiente` | `pendiente` | Nuevo, sin atender |
| `en_proceso` | `en_proceso` | Inspector lo tomó, en gestión |
| `resuelto` | `resuelto` | Cerrado positivamente |
| `rechazado` | `rechazado` | Cerrado negativamente / duplicado |

**Eliminar del enum mobile**: `draft`, `submitted`, `reviewing`, `archived`, `duplicate`, `cancelled`, `inProgress`. El backend solo acepta 4 estados.

**Cambios en inspector_reports_screen.dart:**
- Tab "Pendientes" → filtrar por `status=pendiente`
- Tab "En Proceso" → filtrar por `status=en_proceso`
- Tab "Resueltas" → filtrar por `status=resuelto` y `status=rechazado`

#### Tarea 6.2: Actualizar data source para no enviar estados en inglés
**Archivo a modificar**: `apps/mobile/lib/features/citizen/data/datasources/` y `apps/mobile/lib/features/inspector/data/datasources/`

Enviar siempre estados en español al backend. El backend normaliza pero es mejor enviar correctamente desde origen.

---

### Fase 7: Optimización de Performance
**Prioridad: BAJA | Esfuerzo: Bajo**

#### Tarea 7.1: Reducir frecuencia de auto-refresh
**Archivos a modificar**: Todas las pantallas con Timer.periodic

| Pantalla | Actual | Nuevo |
|----------|--------|-------|
| Citations List | 3s | 30s + pull-to-refresh |
| Reports List | 3s | 30s + pull-to-refresh |
| Inspector Map | 10s | 30s + pull-to-refresh |
| Inspector Home | 10s | 30s + pull-to-refresh |

#### Tarea 7.2: Eliminar código muerto
- Eliminar `inspector_home_screen.dart` (v1)
- Evaluar si el módulo `infractions` en mobile se necesita o se elimina

---

### Fase 8: Widget Compartido - Timeline de Estados
**Prioridad: MEDIA | Esfuerzo: Medio**

#### Tarea 8.1: Crear widget reutilizable StatusTimeline
**Archivo nuevo**: `apps/mobile/lib/shared/widgets/status_timeline_widget.dart`

```dart
class StatusTimelineWidget extends StatelessWidget {
  final List<TimelineEntry> entries;
  // TimelineEntry: { status, timestamp, userName, comment, attachments }
  
  // Renderiza timeline vertical con:
  // - Círculos de color por estado
  // - Líneas conectoras
  // - Texto de comentario
  // - Fotos adjuntas expandibles
  // - Indicador de estado actual (último)
}
```

**Usar en:**
- `ReportDetailScreen` (inspector)
- Detalle de denuncia del ciudadano
- `CitationDetailScreen` (inspector)

---

## 4. ORDEN DE IMPLEMENTACIÓN RECOMENDADO

```
SPRINT 1 (Backend + Base):
├── Tarea 4.4: Verificar/crear tablas de versiones
├── Tarea 4.5: Verificar/crear columnas faltantes en court_citations  
├── Tarea 4.2: Agregar report_id a citaciones
├── Tarea 4.3: Agregar attachments a report_versions
├── Tarea 4.1: Endpoint POST /reports/:id/follow-up
├── Tarea 4.6: Filtro citaciones por reportId
├── Tarea 4.7: Filtro reports por createdBy
└── Tarea 6.1: Normalizar estados en mobile

SPRINT 2 (Inspector Flows):
├── Tarea 1.1: Rediseñar bottom navigation
├── Tarea 1.2: Actualizar home screen
├── Tarea 8.1: Crear StatusTimelineWidget compartido
├── Tarea 2.1: Rediseñar reports screen con sub-tabs
├── Tarea 2.2: Crear pantalla de denuncia del inspector
└── Tarea 2.3: Rediseñar report detail con gestión de etapas

SPRINT 3 (Citaciones + Ciudadano):
├── Tarea 3.1: Mejorar citations list
├── Tarea 3.2: Mejorar create citation (vinculación con reportId)
├── Tarea 3.3: Crear citation detail screen
├── Tarea 5.1: Timeline en detalle de denuncia del ciudadano
└── Tarea 5.2: Push notifications por cambio de estado

SPRINT 4 (Cleanup):
├── Tarea 1.3: Eliminar home screen v1
├── Tarea 6.2: Normalizar envío de estados
├── Tarea 7.1: Reducir auto-refresh
└── Tarea 7.2: Eliminar código muerto
```

---

## 5. ARCHIVOS CLAVE A MODIFICAR (RESUMEN)

### Backend:
| Archivo | Cambio |
|---------|--------|
| `apps/backend/prisma/migrations/XXX_inspector_restructure.sql` | NUEVO: Migración con todas las alteraciones de schema |
| `apps/backend/src/modules/reports/reports.routes.ts` | Agregar ruta POST /:id/follow-up |
| `apps/backend/src/modules/reports/reports.service.ts` | Agregar método addFollowUp(), filtro createdBy |
| `apps/backend/src/modules/reports/reports.types.ts` | Agregar FollowUpDto |
| `apps/backend/src/modules/citations/citations.service.ts` | Agregar reportId a create/find |
| `apps/backend/src/modules/citations/citations.types.ts` | Agregar reportId a DTOs |
| `apps/backend/src/modules/citations/citations.routes.ts` | Agregar filtro por reportId |

### Mobile - Modificar:
| Archivo | Cambio |
|---------|--------|
| `apps/mobile/lib/dashboard/presentation/pages/dashboard_screen.dart` | Navegación 5 tabs |
| `apps/mobile/lib/features/inspector/presentation/pages/inspector_home_screen_v2.dart` | Stats + acciones |
| `apps/mobile/lib/features/inspector/presentation/pages/inspector_reports_screen.dart` | Sub-tabs + mis denuncias |
| `apps/mobile/lib/features/inspector/presentation/pages/report_detail_screen.dart` | Gestión de etapas completa |
| `apps/mobile/lib/features/inspector/presentation/pages/citations_list_screen.dart` | Filtros + vinculación |
| `apps/mobile/lib/features/inspector/presentation/pages/create_citation_screen.dart` | reportId + audiencia |
| `apps/mobile/lib/features/inspector/domain/entities/citation_entity.dart` | reportId field |
| `apps/mobile/lib/features/inspector/data/models/citation_model.dart` | reportId serialización |
| `apps/mobile/lib/features/inspector/data/datasources/citation_api_data_source.dart` | reportId en create |
| `apps/mobile/lib/features/citizen/domain/entities/enhanced_report_entity.dart` | Normalizar estados |

### Mobile - Crear:
| Archivo | Descripción |
|---------|-------------|
| `apps/mobile/lib/features/inspector/presentation/pages/create_inspector_report_screen.dart` | Formulario denuncia inspector |
| `apps/mobile/lib/features/inspector/presentation/pages/citation_detail_screen.dart` | Detalle citación dedicado |
| `apps/mobile/lib/shared/widgets/status_timeline_widget.dart` | Widget timeline reutilizable |

### Mobile - Eliminar:
| Archivo | Razón |
|---------|-------|
| `apps/mobile/lib/features/inspector/presentation/pages/inspector_home_screen.dart` | V1 no usado |

---

## 6. NOTAS PARA EL IMPLEMENTADOR

1. **Antes de empezar**: Verificar en la base de datos de producción qué columnas/tablas ya existen. Puede que migraciones posteriores a 001 ya hayan agregado los campos faltantes.

2. **Patrón de arquitectura**: El proyecto usa **Clean Architecture** con BLoC pattern. Cada feature tiene: domain (entities, repositories, usecases) → data (models, datasources, repository_impl) → presentation (bloc, pages, widgets). Mantener este patrón.

3. **Tema visual**: Usar `AppTheme` existente. Los colores de estado ya están definidos en `citation_ui_extensions.dart`. Reutilizar para reports también.

4. **Testing**: No hay tests unitarios significativos en mobile. Si se agregan, hacerlo para los BLoCs y usecases.

5. **El backend ya normaliza estados** en español. No romper esa normalización.

6. **La tabla se llama `court_citations`** pero conceptualmente son "fiscalizaciones del inspector". No renombrar la tabla (riesgoso), pero sí usar "Citaciones/Notificaciones" en la UI.

7. **Auto-refresh**: Preferir pull-to-refresh + refresh en navigation (cuando se vuelve a la pantalla) sobre Timer.periodic agresivo.
