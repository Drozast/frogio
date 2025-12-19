# 🌐 Guía de Conectividad de Clientes - Frogio

Esta guía explica cómo conectar diferentes clientes (web, móvil) al servidor de producción de Frogio.

---

## 📍 Información del Servidor

### Servidor de Producción
- **IP:** `192.168.31.115`
- **Red:** Local (192.168.31.0/24)

### Servicios Disponibles

| Servicio | Puerto | URL | Descripción |
|----------|--------|-----|-------------|
| Backend API | 3000 | `http://192.168.31.115:3000` | API REST principal |
| Web Admin (Contenedor) | 3010 | `http://192.168.31.115:3010` | Panel admin Next.js |
| PostgreSQL | 5433 | `postgresql://192.168.31.115:5433` | Base de datos (backups) |

---

## 🌐 Web Admin (Next.js)

### Acceso Directo al Contenedor
El Web Admin ya está desplegado y accesible directamente:
```
http://192.168.31.115:3010
```

### Desarrollo Local
Si quieres correr el web-admin localmente y conectarlo al servidor:

**1. Configurar variables de entorno:**

Archivo: `apps/web-admin/.env.local`
```env
NEXT_PUBLIC_API_URL=http://192.168.31.115:3000
NEXT_PUBLIC_TENANT_ID=santa_juana
```

**2. Instalar dependencias y ejecutar:**
```bash
cd apps/web-admin
npm install
npm run dev
```

**3. Abrir en navegador:**
```
http://localhost:3000
```

El navegador se conectará al backend en `192.168.31.115:3000` via AJAX.

---

## 📱 Aplicación Móvil (Flutter)

La app móvil ya está configurada para conectarse al servidor de producción.

### Configuración Actual

**Archivo:** `apps/mobile/lib/core/config/api_config.dart`

```dart
baseUrl: 'http://192.168.31.115:3000'
tenantId: 'santa_juana'
ntfyUrl: 'http://192.168.31.115:8089'
```

### Compilar la App

#### Android - APK Debug (Para Testing)
```bash
cd apps/mobile
flutter build apk --debug
```

El APK estará en:
```
build/app/outputs/flutter-apk/app-debug.apk
```

#### Android - APK Release (Para Producción)
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

### Instalar en Dispositivo

**Método 1: USB/ADB**
```bash
flutter install
# o
adb install build/app/outputs/flutter-apk/app-debug.apk
```

**Método 2: Transferir APK**
- Envía el APK por email/WhatsApp/Drive
- Abre en el dispositivo y permite instalación de fuentes desconocidas
- Instala

### Requisitos para la App Móvil

1. **Misma red WiFi:** El dispositivo debe estar en la red `192.168.31.x`
2. **Permisos:** La app necesita permiso de Internet (ya configurado)
3. **HTTP permitido:** Android/iOS permiten HTTP a IPs locales

---

## 🔐 Usuarios de Prueba

Usa estos usuarios para testing:

### Admin
```
Email: admin@test.cl
Password: Password123!
Role: admin
```

### Inspector
```
Email: inspector@test.cl
Password: Password123!
Role: inspector
```

### Ciudadano
```
Email: ciudadano@test.cl
Password: Password123!
Role: citizen
```

---

## 🧪 Testing de Conectividad

### 1. Verificar que el servidor está corriendo

```bash
curl http://192.168.31.115:3000/health
```

Respuesta esperada:
```json
{
  "status": "ok",
  "timestamp": "2025-12-19T...",
  "services": {
    "database": "connected",
    "redis": "not configured"
  }
}
```

### 2. Probar Login desde Terminal

```bash
curl -X POST http://192.168.31.115:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{
    "email": "admin@test.cl",
    "password": "Password123!"
  }'
```

Respuesta esperada:
```json
{
  "user": {
    "id": "...",
    "email": "admin@test.cl",
    "role": "admin",
    ...
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

### 3. Probar desde Navegador (CORS)

Abre la consola del navegador (F12) y ejecuta:

```javascript
fetch('http://192.168.31.115:3000/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Tenant-ID': 'santa_juana'
  },
  body: JSON.stringify({
    email: 'admin@test.cl',
    password: 'Password123!'
  })
})
.then(r => r.json())
.then(data => console.log('Login exitoso:', data))
.catch(err => console.error('Error:', err));
```

---

## 🔧 Configuración de CORS

El servidor está configurado para **aceptar conexiones desde cualquier origen** (`*`).

Esto permite:
- ✅ Navegadores web desde cualquier IP
- ✅ Apps móviles
- ✅ Desarrollo local (localhost)
- ✅ Postman / Thunder Client

**Configuración en el servidor:**
```yaml
# docker-compose.full.yml
CORS_ORIGIN: "*"
```

**Código del backend:**
```typescript
// server.ts
const corsOrigin = env.CORS_ORIGINS[0] === '*'
  ? true  // Allow all origins
  : env.CORS_ORIGINS;

app.use(cors({
  origin: corsOrigin,
  credentials: true
}));
```

---

## 📡 Endpoints Principales

### Autenticación
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Registro
- `POST /api/auth/refresh` - Refresh token
- `POST /api/auth/logout` - Logout

### Infracciones (Inspectores)
- `GET /api/infractions` - Listar infracciones
- `POST /api/infractions` - Crear infracción
- `GET /api/infractions/:id` - Ver detalle
- `PATCH /api/infractions/:id` - Actualizar
- `DELETE /api/infractions/:id` - Eliminar (admin)

### Reportes (Ciudadanos)
- `GET /api/reports` - Listar reportes
- `POST /api/reports` - Crear reporte
- `GET /api/reports/:id` - Ver detalle
- `PATCH /api/reports/:id` - Actualizar
- `DELETE /api/reports/:id` - Eliminar (admin)

### Usuarios (Admin)
- `GET /api/users` - Listar usuarios
- `POST /api/users` - Crear usuario
- `GET /api/users/:id` - Ver detalle
- `PATCH /api/users/:id` - Actualizar
- `DELETE /api/users/:id` - Eliminar

---

## 🚨 Troubleshooting

### No puedo conectar desde mi dispositivo móvil

**Problema:** La app no se conecta al servidor

**Soluciones:**
1. Verificar que estás en la misma red WiFi (192.168.31.x)
   ```bash
   # En el móvil, verifica tu IP en Settings > WiFi
   ```

2. Hacer ping al servidor desde terminal (si tienes acceso)
   ```bash
   ping 192.168.31.115
   ```

3. Verificar que el backend está corriendo:
   ```bash
   curl http://192.168.31.115:3000/health
   ```

4. Verificar firewall del servidor (si aplica)

### Error de CORS en navegador

**Problema:** `Access-Control-Allow-Origin` error

**Solución:** Ya está configurado con `*`, pero si persiste:
- Verifica que el backend esté corriendo
- Revisa los logs: `docker compose -f docker-compose.full.yml logs backend`
- Verifica la variable CORS_ORIGIN en docker-compose.full.yml

### App móvil muestra "Network Error"

**Problema:** No puede conectar al servidor

**Soluciones:**
1. Verifica la IP en `api_config.dart` es correcta
2. Recompila la app después de cambios:
   ```bash
   flutter build apk --debug
   ```
3. Verifica permisos de Internet en AndroidManifest.xml
4. En iOS, verifica NSAppTransportSecurity en Info.plist

### Servidor responde 404

**Problema:** Endpoint no encontrado

**Verificaciones:**
- URL correcta: `http://192.168.31.115:3000/api/...` (no olvides `/api/`)
- Método HTTP correcto (GET, POST, etc)
- Headers requeridos: `Content-Type`, `X-Tenant-ID`

---

## 📝 Notas Importantes

### Seguridad

⚠️ **Producción Real:**
- Cambiar CORS de `*` a orígenes específicos
- Implementar HTTPS con certificado SSL
- Configurar firewall para limitar acceso
- Usar tokens JWT con expiración corta

### Red Local

✅ **Actualmente:**
- Solo accesible desde red local (192.168.31.0/24)
- No expuesto a Internet
- Ideal para desarrollo y testing interno

### Futuro: Dominio Público

Para exponer Frogio a Internet:
1. Configurar dominio (ej: `frogio.santajuana.cl`)
2. Obtener certificado SSL (Let's Encrypt)
3. Configurar Nginx Proxy Manager
4. Actualizar URLs en app móvil y web-admin
5. Actualizar CORS para orígenes específicos

---

## 🎯 Checklist de Deployment

- [x] Backend corriendo en puerto 3000
- [x] Web Admin corriendo en puerto 3010
- [x] CORS configurado para permitir todos los orígenes
- [x] PostgreSQL funcionando (puerto 5433)
- [x] Usuarios de prueba creados
- [x] Datos migrados correctamente
- [x] Health check funcionando
- [x] Login funcionando desde web y API
- [x] App móvil configurada con URL del servidor
- [ ] APK compilado y distribuido
- [ ] Testing en dispositivos reales

---

## 🆘 Soporte

Si tienes problemas:

1. **Revisar logs:**
   ```bash
   cd ~/frogio
   docker compose -f docker-compose.full.yml logs -f
   ```

2. **Ver estado de servicios:**
   ```bash
   docker compose -f docker-compose.full.yml ps
   ```

3. **Consultar documentación:**
   - [DEPLOYMENT_STATUS.md](./DEPLOYMENT_STATUS.md)
   - [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)
   - [README_PRODUCTION.md](./apps/mobile/README_PRODUCTION.md)
