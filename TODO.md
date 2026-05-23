# FROGIO - Estado de Features y TODO

**Fecha:** 2 Abril 2026
**Revisado contra:** Codigo fuente backend, web-admin, mobile

---

## Estado de Flujos Principales

### AUTH & USUARIOS
| Feature | Estado | Notas |
|---------|--------|-------|
| Login (web + mobile) | OK | JWT access (15min) + refresh (7d), cookies httpOnly |
| Register | OK | Validacion RUT chileno, bcrypt 12 rounds |
| Token refresh | OK | Blacklist en Redis, fallback por JWT expiry |
| Logout | OK | Invalida refresh token en Redis |
| Perfil (get/update) | OK | Incluye familyMembers, location, avatar |
| Password reset (solicitud) | OK | Email SMTP con template branded + fallback ntfy |
| Password reset (ejecucion) | OK | Token 1hr, uso unico, bcrypt nuevo password |
| CRUD usuarios (admin) | OK | List, create, update, delete, toggle status |
| Cambio password (admin) | OK | Admin puede resetear password de cualquier usuario |

### REPORTES
| Feature | Estado | Notas |
|---------|--------|-------|
| Crear reporte (ciudadano) | OK | Con tipo, prioridad, ubicacion, imagenes |
| Listar reportes | OK | Ciudadano ve solo los suyos, inspector/admin ven todos |
| Detalle de reporte | OK | Con mapa, comentarios, historial |
| Actualizar reporte | OK | Inspector/admin, genera version |
| Historial de versiones | OK | Snapshots completos por cada cambio |
| Asignar inspector | OK | Via update de status |
| Transiciones de estado | OK | pendiente -> en_proceso -> resuelto/rechazado |
| Auto-refresh (web) | OK | Cada 30s via useAutoRefresh |

### CITACIONES
| Feature | Estado | Notas |
|---------|--------|-------|
| Crear citacion | OK | advertencia/citacion, multiples target types |
| Listar citaciones | OK | Con busqueda por nombre/rut/patente |
| Import masivo Excel | OK | Hasta 50+ registros, errores por fila |
| Historial de versiones | OK | Identico pattern a reportes |
| Estadisticas | OK | Por tipo, estado, target_type |
| Proximas audiencias | OK | Query por hearing_date |

### INFRACCIONES
| Feature | Estado | Notas |
|---------|--------|-------|
| Crear infraccion | OK | Con severidad (leve/grave/muy_grave) |
| Listar infracciones | OK | Inspector/admin only |
| Estadisticas | OK | Por tipo, estado, severidad |
| Update estado | OK | Via PATCH |

### VEHICULOS & FLOTA
| Feature | Estado | Notas |
|---------|--------|-------|
| Registrar vehiculo | OK | Plate unica por tenant |
| Buscar por patente | OK | Case-insensitive, inspector/admin |
| Bitacora de uso | OK | Start/end con ubicacion GPS |
| Calcular distancia | OK | Haversine formula desde GPS points |
| Dashboard flota | OK | Viajes activos, completados, km total |
| Mapa en vivo | OK | Socket.IO vehiculo:position |

### GPS TRACKING
| Feature | Estado | Notas |
|---------|--------|-------|
| Batch GPS insert | OK | Multiples puntos por request |
| Posiciones en vivo | OK | Socket.IO + polling fallback |
| Historial de rutas | OK | Por vehiculo + rango de fechas |
| Calendario de actividad | OK | Dias con viajes marcados |
| Estadisticas GPS | OK | Velocidad max/promedio, distancia |
| Limpieza datos viejos | OK | >90 dias por defecto |

### GEOFENCES
| Feature | Estado | Notas |
|---------|--------|-------|
| Crear geofence (circulo/poligono) | OK | Admin only |
| Check punto en geofence | OK | Haversine (circulo) + point-in-polygon |
| Eventos de entrada/salida | OK | Registrados automaticamente |
| Listar eventos recientes | OK | Con paginacion |

### PANIC/SOS
| Feature | Estado | Notas |
|---------|--------|-------|
| Crear alerta | OK | Con ubicacion GPS, genera reporte emergencia |
| Responder a alerta | OK | Inspector asignado, actualiza reporte |
| Resolver alerta | OK | Con texto de resolucion |
| Cancelar alerta | OK | Actualiza reporte a rechazado |
| Notificaciones push | OK | Via ntfy con prioridad urgente |
| Estadisticas | OK | Con filtro por fecha |

### NOTIFICACIONES
| Feature | Estado | Notas |
|---------|--------|-------|
| Crear notificacion DB | OK | Titulo, mensaje, tipo, metadata |
| Listar notificaciones | OK | Con filtro read/unread |
| Marcar como leida | OK | Individual y masivo |
| Eliminar notificacion | OK | Soft delete |
| Contador no leidas | OK | Endpoint separado |
| Push notifications (ntfy) | PARCIAL | Solo alertas criticas (panic, password reset) |

### ARCHIVOS
| Feature | Estado | Notas |
|---------|--------|-------|
| Upload a MinIO | OK | Con metadata (entity_type, entity_id) |
| Servir archivo | OK | Stream-based, ruta publica |
| Eliminar archivo | OK | Limpieza en MinIO + DB |
| Listar por entidad | OK | Files asociados a report/citation/etc |

### DASHBOARD
| Feature | Estado | Notas |
|---------|--------|-------|
| Stats generales | OK | Usuarios, reportes, citaciones, vehiculos |
| Actividad reciente | OK | Ultimos 7 dias |
| Graficos por estado | OK | Recharts (web), charts nativos (mobile) |
| Tendencia diaria | OK | Ultimos 30 dias |

### EXPORTS
| Feature | Estado | Notas |
|---------|--------|-------|
| Exportar reportes | OK | JSON/CSV |
| Exportar infracciones | OK | JSON/CSV |
| Exportar usuarios | OK | JSON/CSV |
| Exportar vehiculos | OK | JSON/CSV |
| Reporte estadistico | OK | Admin only |

### REGISTROS MEDICOS
| Feature | Estado | Notas |
|---------|--------|-------|
| Crear registro | OK | Paciente, condicion, tratamiento |
| Listar registros | OK | Ciudadano ve solo los suyos |
| Ver en contexto SOS | OK | Respondedor ve datos medicos |

---

## TODO - Mejoras Pendientes (Priorizadas)

### ALTA PRIORIDAD (COMPLETADO)

- [x] **Rate limiting en endpoints de auth** - Implementado: authRateLimit (10/15min), passwordResetRateLimit (3/hr), apiRateLimit global
- [x] **Envio real de emails** - Implementado: EmailService con nodemailer, templates HTML branded, fallback a ntfy
- [x] **Paginacion en endpoints de listado** - Implementado en reports, citations, infractions, users, notifications. Response: { data, pagination }
- [x] **Validacion de inputs con schema** - Zod ya estaba para env vars. Error codes estructurados agregados via AppError + Errors factory
- [x] **Sincronizar Prisma schema** - 15 modelos tenant agregados con @@ignore, columnas exactas de migrations SQL

### MEDIA PRIORIDAD

- [ ] **Push notifications reales (FCM)** - Mobile depende de polling cada 30s. Implementar Firebase Cloud Messaging para push real
- [x] **Verificacion tenant vs JWT** - Implementado en authMiddleware: verifica X-Tenant-ID vs JWT tenantId
- [x] **Eliminar console.logs de produccion** - Reemplazados con winston logger en auth, gps-tracking, geofences
- [x] **Codigos de error estructurados** - Implementado: AppError class + Errors factory con codigos (AUTH_*, VALIDATION_*, RESOURCE_*, etc)
- [ ] **Audit logging** - No hay trail de auditoria para operaciones sensibles (cambios de rol, status, pagos)
- [x] **Menu mobile responsive (web-admin)** - Implementado: MobileMenu con drawer animado, hamburger button, backdrop blur
- [ ] **Formularios multi-step** - Algunos formularios son muy largos (citations/new = 686 lineas), podrian ser wizards

### BAJA PRIORIDAD

- [ ] **API versioning** - No hay estrategia de versionado para backward compatibility
- [ ] **Caching con Redis** - Redis disponible pero no usado para cache de datos frecuentes
- [ ] **Request timeouts** - No hay configuracion explicita de timeout en el backend
- [ ] **CSP headers** - Helmet configurado pero sin Content Security Policy
- [ ] **CORS restrictivo en produccion** - CORS permite "*" en desarrollo
- [ ] **Tests E2E de aislamiento multi-tenant** - No hay tests documentados de cross-tenant access prevention
- [ ] **Dark mode mobile** - Solo light theme implementado
- [ ] **Offline support mobile** - No hay queue de operaciones offline

---

## Warnings Actuales

### Mobile (Flutter) - 1 info
- `use_build_context_synchronously` en notification_manager.dart:118 - Patron inherente al singleton, no fixeable sin refactor mayor

### Web Admin - 0 warnings
- Todos los ESLint warnings corregidos

### Backend - Sin analisis estatico configurado
- Recomendacion: agregar ESLint + Prettier al backend

---

## Archivos de Referencia

- `FLOWS.md` - Documentacion completa de todos los flujos de la aplicacion (1958 lineas)
- `DEPLOYMENT_GUIDE.md` - Guia de despliegue
- `API.md` - Documentacion parcial de API
