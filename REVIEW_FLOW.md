# FROGIO - Flujo de Revisión y Cierre de App

**Fecha:** 9 Abril 2026  
**Estado:** Código local adelantado ~83 archivos vs producción (sin commit ni deploy)

---

## ESTADO ACTUAL

### ✅ Lo que funciona (local + producción)
- Auth completo: login, register, refresh token, logout, password reset
- CRUD reportes, citaciones, infracciones, usuarios
- GPS tracking + mapas en vivo (Socket.IO)
- Fleet management: bitácora, historial rutas, calendario actividad
- Geofences: crear/editar, eventos entrada/salida
- Panic/SOS: alerta → respuesta → resolución
- Notificaciones DB + push via ntfy
- Archivos via MinIO (upload/stream/delete)
- Dashboard: stats, gráficos, actividad reciente
- Exports CSV/JSON
- Multi-tenant aislamiento por schema PostgreSQL
- Web-admin: build limpio, 0 warnings
- Mobile Flutter: 1 info (conocido, no bloqueante)

### ⚠️ Cambios locales SIN COMMIT ni deploy (~83 archivos modificados)
- **Backend:** Rate limiting, email service, pagination middleware, error handler, auth tenant check, logger en todos los controllers
- **Mobile:** URLs migradas drozast.xyz → supertools.cl, animaciones UX, nuevos íconos
- **Web-admin:** Framer-motion UX overhaul completo, menu mobile, tiles migrados a supertools.cl
- **Docs:** FLOWS.md (1958 líneas), TODO.md generados

---

## PASO 1: COMMIT Y DEPLOY A PRODUCCIÓN

### 1.1 Commit local
```bash
cd /Users/drozast/frogio
git add apps/backend/ apps/web-admin/ apps/mobile/lib/ apps/mobile/android/ apps/mobile/ios/ docker-compose.yml FLOWS.md TODO.md
git commit -m "feat: UX overhaul, rate limiting, pagination, email service, domain migration supertools.cl"
git push
```

### 1.2 Deploy backend
```bash
# SSH al servidor
ssh -o ProxyCommand="cloudflared access ssh --hostname ssh.supertools.cl" -o StrictHostKeyChecking=no drozast@ssh.supertools.cl

# En el servidor:
cd /home/drozast/frogio-backend
git pull
npm install  # por si hay nuevas deps (express-rate-limit, nodemailer)
docker-compose restart frogio-backend

# Verificar logs
docker logs frogio-backend --tail=50
```

### 1.3 Deploy web-admin
```bash
# En el servidor:
cd /home/drozast/frogio-web-admin
git pull
npm install  # framer-motion
npm run build
docker-compose restart frogio-web-admin

# Verificar
curl -I https://admin-frogio.supertools.cl
```

### 1.4 Verificar backend API
```bash
curl https://api-frogio.supertools.cl/health
# Esperado: {"status":"ok","timestamp":"..."}
```

---

## PASO 2: REINSTALAR APP MÓVIL (CRÍTICO - URLs cambiaron)

La app instalada en los dispositivos todavía apunta a **drozast.xyz** (dominio anterior).  
Hay que recompilar e instalar con las nuevas URLs **supertools.cl**.

### 2.1 Android (YAL L21)
```bash
cd /Users/drozast/frogio/apps/mobile
flutter build apk --release
# Instalar vía USB
flutter install
```

### 2.2 iPhone (Damian's iPhone)
```bash
cd /Users/drozast/frogio/apps/mobile
flutter build ios --release
# Instalar via Xcode o flutter install
open ios/Runner.xcworkspace  # seleccionar dispositivo → Run
```

---

## PASO 3: VERIFICAR CREDENCIALES EN PRODUCCIÓN

Credenciales reseteadas (confirmar que siguen activas):

| Rol | Email | Password |
|-----|-------|----------|
| Ciudadano | ciudadano@frogio.cl | Ciudadano2024! |
| Inspector | inspector@frogio.cl | Inspector2024! |
| Admin | admin@frogio.cl | Admin2024! |

### Verificar via API
```bash
curl -X POST https://api-frogio.supertools.cl/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{"email":"ciudadano@frogio.cl","password":"Ciudadano2024!"}'
# Esperado: {"accessToken":"...","refreshToken":"...","user":{...}}
```

Si falla, regenerar en servidor:
```bash
# En servidor:
docker exec frogio-backend node -e "
const bcrypt = require('bcryptjs');
console.log(bcrypt.hashSync('Ciudadano2024!', 12));
console.log(bcrypt.hashSync('Inspector2024!', 12));
console.log(bcrypt.hashSync('Admin2024!', 12));
"
# Actualizar en DB:
docker exec frogio-postgres psql -U postgres frogio_production -c "
  UPDATE santa_juana.users SET password_hash='\$2b\$12\$...' WHERE email='ciudadano@frogio.cl';
"
```

---

## PASO 4: TEST INDIVIDUAL CIUDADANO

### 4.1 Auth
- [ ] Login con ciudadano@frogio.cl → debe entrar a HomeScreen ciudadano
- [ ] Verificar nombre/avatar en header
- [ ] Logout → volver a login screen
- [ ] Login de nuevo (refresh token debe funcionar si < 7 días)

### 4.2 Crear Reporte
- [ ] Tap "Nuevo Reporte" o botón FAB
- [ ] Seleccionar categoría (ruido, basura, alumbrado, etc.)
- [ ] Marcar ubicación en mapa (verificar tiles supertools.cl)
- [ ] Agregar descripción
- [ ] Adjuntar foto (cámara o galería)
- [ ] Enviar → debe aparecer en lista con estado "pendiente"

### 4.3 Ver mis reportes
- [ ] Lista de reportes propios visible
- [ ] Tap en reporte → ver detalle completo
- [ ] Ver mapa con ubicación del reporte
- [ ] Ver historial de versiones/estados

### 4.4 Perfil
- [ ] Ver datos del perfil
- [ ] Actualizar nombre/teléfono
- [ ] Ver familiares registrados (si aplica)

### 4.5 Registros Médicos (si tiene)
- [ ] Ver propios registros médicos

### 4.6 Notificaciones
- [ ] Bell icon muestra badge con no-leídas
- [ ] Lista de notificaciones
- [ ] Marcar como leídas

---

## PASO 5: TEST INDIVIDUAL INSPECTOR

### 5.1 Auth
- [ ] Login con inspector@frogio.cl → debe entrar a HomeScreen inspector
- [ ] Verificar rol correcto (no debe ver opciones de ciudadano)

### 5.2 Dashboard Inspector
- [ ] Ver stats: reportes activos, citaciones, infracciones hoy
- [ ] Gráficos de actividad

### 5.3 Mapa en Vivo
- [ ] Abrir mapa inspector
- [ ] Ver ubicaciones de reportes activos en mapa
- [ ] Tiles OSM cargando (maps.supertools.cl)
- [ ] Tap en marcador → ver detalle de reporte

### 5.4 Gestión de Reportes
- [ ] Ver todos los reportes del tenant
- [ ] Filtrar por estado (pendiente, en proceso, resuelto)
- [ ] Tap en reporte → ver detalle
- [ ] Actualizar estado a "en_proceso"
- [ ] Agregar comentario
- [ ] Actualizar estado a "resuelto"

### 5.5 Citaciones
- [ ] Lista de citaciones
- [ ] Crear nueva citación (tipo, RUT, descripción, fecha audiencia)
- [ ] Ver detalle de citación existente

### 5.6 Infracciones
- [ ] Lista de infracciones
- [ ] Crear infracción (severidad leve/grave/muy_grave)
- [ ] Ver historial de infracciones por RUT

### 5.7 GPS / Flota (si inspector tiene vehículo)
- [ ] Ver vehículos disponibles
- [ ] Iniciar bitácora de uso
- [ ] GPS tracking activo (mandar puntos GPS)
- [ ] Finalizar bitácora

---

## PASO 6: TEST CONJUNTO CIUDADANO + INSPECTOR

### 6.1 Flujo Reporte Completo
1. **[CIUDADANO]** Crear reporte "Luminaria caída" en ubicación específica
2. **[INSPECTOR]** Recibir notificación de nuevo reporte
3. **[INSPECTOR]** Asignar el reporte (cambiar a "en_proceso")
4. **[CIUDADANO]** Ver que el estado cambió (auto-refresh 30s o manual)
5. **[INSPECTOR]** Resolver el reporte con comentario
6. **[CIUDADANO]** Ver estado "resuelto" y notificación

### 6.2 Flujo SOS/Pánico
1. **[CIUDADANO]** Activar botón de pánico/SOS
2. **[INSPECTOR]** Recibir alerta de pánico (notificación urgente)
3. **[INSPECTOR]** Responder a la alerta (asignarse)
4. **[INSPECTOR]** Resolver o cancelar la alerta
5. **[CIUDADANO]** Confirmar que la alerta se cerró

### 6.3 Flujo Notificaciones en Tiempo Real
1. **[INSPECTOR]** Actualizar estado de reporte del ciudadano
2. **[CIUDADANO]** Verificar que recibe notificación push o in-app < 60s
3. Verificar que el contador de no-leídas se actualiza

---

## PASO 7: TEST WEB ADMIN

### 7.1 Login Admin
- [ ] https://admin-frogio.supertools.cl → login con admin@frogio.cl
- [ ] Verificar animación de página (framer-motion)
- [ ] Verificar sidebar con animaciones

### 7.2 Dashboard
- [ ] Stats cards con contadores animados
- [ ] Gráficos Recharts cargando
- [ ] Actividad reciente

### 7.3 Usuarios
- [ ] Lista de usuarios con paginación
- [ ] Crear usuario nuevo
- [ ] Editar usuario existente
- [ ] Toggle status (activar/desactivar)

### 7.4 Reportes (admin)
- [ ] Lista paginada de todos los reportes
- [ ] Filtros funcionando
- [ ] Detalle con mapa (tiles supertools.cl)
- [ ] Cambiar estado
- [ ] Export CSV

### 7.5 Citaciones
- [ ] Lista de citaciones
- [ ] Crear nueva citación manualmente
- [ ] Import masivo Excel
- [ ] Ver estadísticas

### 7.6 Infracciones
- [ ] Lista con filtros
- [ ] Stats por severidad

### 7.7 Flota
- [ ] Lista de vehículos
- [ ] Registrar vehículo nuevo
- [ ] Ver historial de uso (bitácoras)
- [ ] Ver historial de rutas GPS (calendario actividad)
- [ ] Mapa en vivo (Socket.IO)

### 7.8 Geofences
- [ ] Ver geofences existentes
- [ ] Crear geofence circular
- [ ] Crear geofence poligonal
- [ ] Ver eventos de entrada/salida

### 7.9 Mobile Responsive
- [ ] Achicar browser a mobile width
- [ ] Hamburger menu aparece
- [ ] Drawer animado se abre/cierra
- [ ] Toda navegación funciona desde drawer

---

## PASO 8: VERIFICAR RATE LIMITING EN PRODUCCIÓN

```bash
# Test: intentar login mal 11 veces (límite = 10 en 15min)
for i in {1..12}; do
  curl -X POST https://api-frogio.supertools.cl/api/auth/login \
    -H "Content-Type: application/json" \
    -H "X-Tenant-ID: santa_juana" \
    -d '{"email":"test@test.com","password":"wrong"}' \
    -s -o /dev/null -w "Request $i: %{http_code}\n"
done
# Esperado: primeros 10 = 401, request 11+ = 429 Too Many Requests
```

---

## PASO 9: VERIFICAR PAGINACIÓN EN PRODUCCIÓN

```bash
TOKEN=$(curl -s -X POST https://api-frogio.supertools.cl/api/auth/login \
  -H "Content-Type: application/json" -H "X-Tenant-ID: santa_juana" \
  -d '{"email":"admin@frogio.cl","password":"Admin2024!"}' | jq -r '.accessToken')

curl "https://api-frogio.supertools.cl/api/reports?page=1&limit=5" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: santa_juana" | jq '.pagination'
# Esperado: {"page":1,"limit":5,"total":X,"totalPages":Y,"hasNext":true/false,...}
```

---

## ISSUES CONOCIDOS Y PENDIENTES

### Bloqueantes (deben resolverse antes de entregar)
| Issue | Descripción | Acción |
|-------|-------------|--------|
| **DEPLOY** | Código local sin deploy | Pasos 1.2 y 1.3 |
| **MOBILE URLs** | App instalada tiene URLs viejas | Paso 2 completo |
| **CREDENCIALES** | Podrían haber expirado | Verificar Paso 3 |

### No Bloqueantes (mejoras post-lanzamiento)
| Feature | Prioridad | Descripción |
|---------|-----------|-------------|
| Push FCM | Media | Notificaciones push reales (ahora solo ntfy/polling) |
| Audit logging | Media | Trail de auditoría para ops sensibles |
| Dark mode mobile | Baja | Solo light theme |
| Offline mobile | Baja | Sin queue de operaciones offline |
| API versioning | Baja | Sin estrategia v1/v2 |
| Redis caching | Baja | Redis disponible pero sin caché de datos |
| Tests E2E | Baja | Aislamiento multi-tenant no testado automáticamente |
| Formularios wizard | Baja | citations/new son 686 líneas, candidato a multi-step |

---

## CHECKLIST FINAL DE CIERRE

```
PRE-DEPLOY
[x] git commit con todos los cambios (83 archivos)
[x] git push al repo

SERVIDOR
[x] frogio-backend redesplegado y respondiendo /health
[ ] frogio-web-admin redesplegado y cargando CSS/JS
[x] docker logs sin errores críticos

MOBILE
[ ] APK android recompilado con URLs supertools.cl
[ ] iOS recompilado con URLs supertools.cl
[ ] Ambos instalados en dispositivos de prueba

CREDENCIALES
[x] Login ciudadano funciona via API  (ciudadano@test.cl / Ciudadano2024!)
[x] Login inspector funciona via API  (inspector@test.cl / Inspector2024!)
[x] Login admin funciona via API      (admin@test.cl / Admin2024!)

TESTS FUNCIONALES (API automatizada 25/26 ✅)
[x] Ciudadano: login, crear reporte, ver reporte, notificaciones
[x] Inspector: login, ver reportes, actualizar estado (en_proceso → resuelto)
[ ] Admin web: login, dashboard, CRUD usuarios, export
[ ] Flujo conjunto: reporte ciudadano → actualización inspector → notificación
[ ] Flujo SOS: pánico ciudadano → respuesta inspector → cierre

TÉCNICO
[x] Rate limiting activo (429 en request #7)
[x] Paginación en respuestas API (page, limit, total, totalPages)
[ ] Tiles OSM cargando desde maps.supertools.cl
[ ] Socket.IO conecta en mapa en vivo

BUGS CORREGIDOS (backend)
[x] citations.service.ts: hearing_date → ::timestamptz cast
[x] geofences.service.ts: columnas type/radius/polygon (nombres correctos)
[x] infractions: userId + amount requeridos en CREATE
[x] Docker image reconstruida y deployada en producción

ENTREGA
[ ] TODO.md actualizado con estado final
[ ] FLOWS.md refleja flujos reales
```

---

## TIEMPOS ESTIMADOS

| Tarea | Tiempo |
|-------|--------|
| Commit + push | 5 min |
| Deploy backend | 5 min |
| Deploy web-admin (build incluido) | 10 min |
| Recompilar + instalar Android | 10 min |
| Recompilar + instalar iOS | 15 min |
| Test ciudadano completo | 20 min |
| Test inspector completo | 20 min |
| Test flujos conjuntos | 15 min |
| Test web admin | 20 min |
| **Total estimado** | **~2 horas** |
