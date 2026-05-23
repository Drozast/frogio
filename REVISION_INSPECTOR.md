# Revisión Módulo Inspector
> Fecha: 2026-04-12 | Tester: _________________

Leyenda: ✅ OK | ❌ Error | ⚠️ Parcial | ⬜ Pendiente

---

## 🏠 Home

| # | Flujo | Estado | Notas |
|---|-------|--------|-------|
| 1 | Stats cargan: denuncias pendientes, citaciones hoy, alertas SOS | ⬜ | |
| 2 | Tap en stat card de denuncias → navega al tab Denuncias | ⬜ | |
| 3 | Pull-to-refresh actualiza todo | ⬜ | |
| 4 | Botón "Nueva Denuncia" → abre formulario | ⬜ | |
| 5 | Botón "Nueva Citación" → abre formulario | ⬜ | |
| 6 | Botón "Mapa" → abre mapa | ⬜ | |

---

## 📋 Denuncias — Segmento Ciudadanas

| # | Flujo | Estado | Notas |
|---|-------|--------|-------|
| 7 | Sub-tab Pendientes carga solo status=pendiente | ⬜ | |
| 8 | Sub-tab En Proceso carga solo status=en_proceso | ⬜ | |
| 9 | Sub-tab Resueltas carga resuelto y rechazado | ⬜ | |
| 10 | Tap en card → abre detalle de denuncia | ⬜ | |
| 11 | Pull-to-refresh en cada tab | ⬜ | |
| 12 | FAB "Nueva Denuncia" NO visible en este segmento | ⬜ | |

---

## 📋 Denuncias — Segmento Mis Denuncias

| # | Flujo | Estado | Notas |
|---|-------|--------|-------|
| 13 | Lista carga solo denuncias creadas por el inspector | ⬜ | |
| 14 | Sub-tabs Pendientes / En Proceso / Resueltas funcionan | ⬜ | |
| 15 | FAB "Nueva Denuncia" visible solo en este segmento | ⬜ | |
| 16 | Tap FAB → abre CreateInspectorReportScreen | ⬜ | |

---

## ➕ Crear Denuncia (Inspector)

| # | Flujo | Estado | Notas |
|---|-------|--------|-------|
| 17 | GPS se activa automáticamente al abrir | ⬜ | |
| 18 | Badge muestra "GPS activo" cuando hay coordenadas | ⬜ | |
| 19 | Ubicación se pre-selecciona con GPS | ⬜ | |
| 20 | Prioridad default es Alta | ⬜ | |
| 21 | Validación: título vacío muestra error | ⬜ | |
| 22 | Validación: descripción < 20 chars muestra error | ⬜ | |
| 23 | Dropdown de categoría funciona | ⬜ | |
| 24 | Puede adjuntar fotos | ⬜ | |
| 25 | Botón Enviar en AppBar funciona | ⬜ | |
| 26 | Dialog de éxito al crear → vuelve a la lista | ⬜ | |
| 27 | Denuncia aparece en "Mis Denuncias" después de crear | ⬜ | |

---

## 🔍 Detalle de Denuncia (rol inspector)

| # | Flujo | Estado | Notas |
|---|-------|--------|-------|
| 28 | Tab Info: título, descripción, ubicación, fotos | ⬜ | |
| 29 | Tab Timeline: historial de etapas visible | ⬜ | |
| 30 | Tab Respuestas: comentarios visibles | ⬜ | |
| 31 | Tab Citaciones: lista de citaciones vinculadas | ⬜ | |
| 32 | Denuncia pendiente → botón "Tomar Denuncia" visible | ⬜ | |
| 33 | Tap "Tomar Denuncia" → status cambia a en_proceso | ⬜ | |
| 34 | Denuncia en_proceso → botón "Seguimiento" visible | ⬜ | |
| 35 | Tap "Seguimiento" → modal con campo nota → guarda | ⬜ | |
| 36 | Botón "Citación" → navega a crear citación con reportId | ⬜ | |
| 37 | Botón "Resolver" → dialog con comentario → status resuelto | ⬜ | |
| 38 | Botón "Rechazar" → dialog con comentario → status rechazado | ⬜ | |
| 39 | Timeline se actualiza después de cada acción | ⬜ | |

---

## 📑 Lista de Citaciones

| # | Flujo | Estado | Notas |
|---|-------|--------|-------|
| 40 | Lista carga correctamente | ⬜ | |
| 41 | Filtro por estado funciona | ⬜ | |
| 42 | Cards muestran badge de denuncia vinculada (si tiene) | ⬜ | |
| 43 | Tap en card → abre CitationDetailScreen (pantalla completa) | ⬜ | |
| 44 | Pull-to-refresh funciona | ⬜ | |

---

## ➕ Crear Citación

| # | Flujo | Estado | Notas |
|---|-------|--------|-------|
| 45 | GPS se activa al abrir | ⬜ | |
| 46 | Tipo Advertencia: no muestra sección de audiencia | ⬜ | |
| 47 | Tipo Citación: muestra sección "Datos de Audiencia" | ⬜ | |
| 48 | DatePicker de fecha de audiencia funciona | ⬜ | |
| 49 | Campo juzgado acepta texto | ⬜ | |
| 50 | Objetivo Persona: muestra campo RUT | ⬜ | |
| 51 | RUT se auto-formatea (12.345.678-9) | ⬜ | |
| 52 | Objetivo Vehículo: muestra campo patente | ⬜ | |
| 53 | Fotos adjuntas funcionan (máx 5) | ⬜ | |
| 54 | Número de citación se genera con folio ingresado | ⬜ | |
| 55 | Creada desde detalle de denuncia → reportId pre-cargado | ⬜ | |
| 56 | Al guardar → vuelve a pantalla anterior | ⬜ | |

---

## 📄 Detalle de Citación

| # | Flujo | Estado | Notas |
|---|-------|--------|-------|
| 57 | Muestra tipo, objetivo, motivo, fecha | ⬜ | |
| 58 | Tipo Citación → muestra fecha audiencia y juzgado | ⬜ | |
| 59 | Muestra RUT si objetivo es persona | ⬜ | |
| 60 | Muestra patente si objetivo es vehículo | ⬜ | |
| 61 | Sección "Denuncia vinculada" visible si tiene reportId | ⬜ | |
| 62 | Tap en denuncia vinculada → navega al detalle | ⬜ | |
| 63 | Status pendiente → botón "Actualizar Estado" visible | ⬜ | |
| 64 | Bottom sheet: seleccionar Notificado / Asistió / No Asistió / Cancelado | ⬜ | |
| 65 | Campo de nota opcional en bottom sheet | ⬜ | |
| 66 | Guardar status → se refleja en el detalle | ⬜ | |

---

## 🗺️ Mapa

| # | Flujo | Estado | Notas |
|---|-------|--------|-------|
| 67 | Carga reportes como pins | ⬜ | |
| 68 | Tap en pin → abre EnhancedReportDetailScreen | ⬜ | |
| 69 | Botón "Mi ubicación" centra el mapa | ⬜ | |
| 70 | Refresh cada 30s (no se congela la UI) | ⬜ | |

---

## 👤 Perfil

| # | Flujo | Estado | Notas |
|---|-------|--------|-------|
| 71 | Datos del inspector se muestran correctamente | ⬜ | |
| 72 | Foto de perfil carga si tiene una asignada | ⬜ | |
| 73 | Cambiar foto de perfil (cámara / galería) | ⬜ | |
| 74 | Cerrar sesión funciona | ⬜ | |

---

## Resumen

| Total | ✅ OK | ❌ Error | ⚠️ Parcial | ⬜ Pendiente |
|-------|--------|---------|------------|-------------|
| 74    | 0      | 0       | 0          | 74          |

---

## Bugs Encontrados

| # | Pantalla | Descripción | Prioridad |
|---|----------|-------------|-----------|
| | | | |
