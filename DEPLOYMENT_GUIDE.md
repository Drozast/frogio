# 🚀 FROGIO - Guía de Deployment Completa

## 📋 Pre-requisitos Completados

✅ **Infraestructura Configurada:**
- PostgreSQL 16 (192.168.31.115:5432)
- Redis 7 (192.168.31.115:6379)
- MinIO (192.168.31.115:9002/9003)
- ntfy (192.168.31.115:8089)
- Cloudflare Tunnel configurado
- Coolify instalado (https://coolify.drozast.xyz)

✅ **Credenciales Generadas:**
- JWT secrets
- Database password
- MinIO access keys
- Google OAuth credentials

---

## 🗄️ Paso 1: Ejecutar Migraciones de Base de Datos

### Opción A: Desde tu máquina local

```bash
cd apps/backend/prisma
./run-migration.sh
```

El script te pedirá confirmación y ejecutará las migraciones en la base de datos de producción.

### Opción B: Desde el servidor directamente

```bash
# Conectar al servidor
ssh drozast@192.168.31.115

# Instalar PostgreSQL client si no está
sudo apt install postgresql-client -y

# Descargar el archivo de migración
cd ~
mkdir -p frogio-migrations
cd frogio-migrations

# Copiar el archivo SQL (desde tu máquina local)
# scp apps/backend/prisma/migrations/001_initial_setup.sql drozast@192.168.31.115:~/frogio-migrations/

# Ejecutar migración
PGPASSWORD='N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=' psql -h localhost -U frogio -d frogio -f 001_initial_setup.sql
```

### Verificar que las migraciones se ejecutaron correctamente

```bash
# Listar schemas
PGPASSWORD='N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=' psql -h localhost -U frogio -d frogio -c '\dn'

# Listar tablas del schema santa_juana
PGPASSWORD='N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=' psql -h localhost -U frogio -d frogio -c '\dt santa_juana.*'

# Verificar el tenant creado
PGPASSWORD='N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=' psql -h localhost -U frogio -d frogio -c 'SELECT * FROM public.tenants;'
```

---

## 🔧 Paso 2: Configurar Variables de Entorno en Coolify

1. **Acceder a Coolify**: https://coolify.drozast.xyz
2. **Ir a**: Projects → FROGIO → frogio-backend
3. **Environment Variables**: Copiar las variables del archivo `.env` de producción

### Variables Críticas a Configurar:

```env
NODE_ENV=production
PORT=3000
API_URL=https://api.drozast.xyz
ADMIN_URL=https://admin.drozast.xyz

DATABASE_URL=postgresql://frogio:N8H%2BJG%2FUTBQVE6G%2BqUJAil4n%2FMkLjks%2Fo7LzMBnrU40%3D@192.168.31.115:5432/frogio

REDIS_URL=redis://192.168.31.115:6379

MINIO_ENDPOINT=192.168.31.115
MINIO_PORT=9002
MINIO_ACCESS_KEY=admin
MINIO_SECRET_KEY=Y5/iqYWfm7MjHx8V1pHNRNgnJe7F7Mz1SJ3n9LK5+Lk=
MINIO_BUCKET=frogio
MINIO_USE_SSL=false

JWT_SECRET=57Xs6jLFa4hlQh/QQmEAqGAaGqab8veiEZ8OvprM1YMABWKMes3UCG8w2546p5+n
JWT_REFRESH_SECRET=y6lrRgxVVdMh0MN7KthK2TPcStvuE6DX/5cg6SIOLjBaFCnD2EX2lh6QSBarai+f
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

GOOGLE_CLIENT_ID=663555551489-q39gs8sj40ghssneuske45vv5h1pbmrr.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
GOOGLE_CALLBACK_URL=https://api.drozast.xyz/api/auth/google/callback

NTFY_URL=http://192.168.31.115:8089
NTFY_BASE_URL=https://ntfy.drozast.xyz

CORS_ORIGIN=https://admin.drozast.xyz,https://drozast.xyz

SMTP_HOST=localhost
SMTP_PORT=587
SMTP_USER=temp@localhost
SMTP_PASSWORD=temppassword
SMTP_FROM=noreply@localhost
SMTP_SECURE=false

RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

NIXPACKS_NODE_VERSION=22
```

**⚠️ IMPORTANTE:** Asegúrate de que la `DATABASE_URL` tiene los caracteres especiales URL-encoded:
- `+` → `%2B`
- `/` → `%2F`
- `=` → `%3D`

---

## 📦 Paso 3: Deploy del Backend

### En Coolify:

1. **Source Code:**
   - Repository: `git@github.com:Drozast/frogio.git`
   - Branch: `main`
   - Base Directory: `/apps/backend`

2. **Build Settings:**
   - Build Pack: Nixpacks
   - Port: 3000
   - Install Command: `npm install`
   - Build Command: `npm run build`
   - Start Command: `npm start`

3. **Network:**
   - Port: 3000
   - Domain: `https://api.drozast.xyz` (ya configurado en Cloudflare Tunnel)

4. **Trigger Deploy:**
   - Click "Deploy"
   - Espera 2-3 minutos
   - Monitorea los logs

### Verificar Deployment:

```bash
# Check health endpoint
curl https://api.drozast.xyz/health

# Expected response:
# {
#   "status": "ok",
#   "timestamp": "2024-12-14T...",
#   "services": {
#     "database": "connected",
#     "redis": "connected"
#   }
# }

# Check API info
curl https://api.drozast.xyz/api

# Check logs desde el servidor
ssh drozast@192.168.31.115
sudo docker logs $(sudo docker ps -q --filter "name=cs4ck") --tail 100 -f
```

---

## 🧪 Paso 4: Probar la API

### 1. Registrar un usuario (ciudadano)

```bash
curl -X POST https://api.drozast.xyz/api/auth/register \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{
    "email": "juan.perez@example.com",
    "password": "Password123!",
    "rut": "12345678-9",
    "firstName": "Juan",
    "lastName": "Pérez",
    "phone": "+56912345678"
  }'
```

**Respuesta esperada:**
```json
{
  "user": {
    "id": "uuid...",
    "email": "juan.perez@example.com",
    "rut": "12345678-9",
    "firstName": "Juan",
    "lastName": "Pérez",
    "phone": "+56912345678",
    "role": "citizen",
    "isActive": true
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

Guarda el `accessToken` para los siguientes requests.

### 2. Login

```bash
curl -X POST https://api.drozast.xyz/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{
    "email": "juan.perez@example.com",
    "password": "Password123!"
  }'
```

### 3. Crear un reporte

```bash
curl -X POST https://api.drozast.xyz/api/reports \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "type": "denuncia",
    "title": "Bache en calle principal",
    "description": "Hay un bache grande en la calle O'\''Higgins que necesita reparación",
    "address": "Calle O'\''Higgins 123, Santa Juana",
    "latitude": -37.1234,
    "longitude": -72.5678,
    "priority": "media"
  }'
```

### 4. Listar reportes

```bash
curl -X GET https://api.drozast.xyz/api/reports \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 🔍 Paso 5: Monitoreo y Debugging

### Ver logs en tiempo real:

```bash
# Conectar al servidor
ssh drozast@192.168.31.115

# Ver logs del backend
sudo docker logs $(sudo docker ps -q --filter "name=cs4ck") --tail 100 -f

# Ver IP del contenedor (para Cloudflare Tunnel)
sudo docker inspect $(sudo docker ps -q --filter "name=cs4ck") --format '{{.NetworkSettings.Networks.coolify.IPAddress}}'
```

### Verificar servicios:

```bash
# PostgreSQL
sudo docker exec -it postgres psql -U frogio -d frogio -c 'SELECT version();'

# Redis
sudo docker exec -it redis redis-cli ping

# MinIO
curl http://192.168.31.115:9002/minio/health/live
```

### Actualizar Cloudflare Tunnel si cambió la IP del contenedor:

```bash
# Editar config
sudo nano /etc/cloudflared/config.yml

# Cambiar la IP en la línea:
# service: http://10.0.1.X:3000

# Reiniciar tunnel
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

---

## 📱 Paso 6: Deploy del Web Admin (Pendiente)

```bash
# En Coolify, crear nueva aplicación
Project: FROGIO
Name: frogio-web-admin
Repository: git@github.com:Drozast/frogio.git
Branch: main
Base Directory: /apps/web-admin
Build Pack: Nixpacks
Port: 3001
Domain: https://admin.drozast.xyz
```

**Variables de entorno para web-admin:**
```env
NEXT_PUBLIC_API_URL=https://api.drozast.xyz
NEXT_PUBLIC_TENANT_ID=santa_juana
```

---

## 🐛 Troubleshooting Común

### Error: "Cannot connect to database"

**Causa:** Password con caracteres especiales no está URL-encoded.

**Solución:**
```env
# ❌ Incorrecto
DATABASE_URL=postgresql://frogio:N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=@...

# ✅ Correcto
DATABASE_URL=postgresql://frogio:N8H%2BJG%2FUTBQVE6G%2BqUJAil4n%2FMkLjks%2Fo7LzMBnrU40%3D@...
```

### Error: "Token inválido o expirado"

**Causa:** JWT_SECRET no coincide o está vacío.

**Solución:** Verificar que `JWT_SECRET` y `JWT_REFRESH_SECRET` estén configurados en Coolify.

### Error: "Tenant ID requerido en headers"

**Causa:** Falta el header `X-Tenant-ID` en el request.

**Solución:**
```bash
curl ... -H "X-Tenant-ID: santa_juana" ...
```

### Error 502 Bad Gateway en Cloudflare

**Causa:** IP del contenedor cambió después de redeploy.

**Solución:**
```bash
# 1. Obtener nueva IP
sudo docker inspect $(sudo docker ps -q --filter "name=cs4ck") --format '{{.NetworkSettings.Networks.coolify.IPAddress}}'

# 2. Actualizar Cloudflare Tunnel config
sudo nano /etc/cloudflared/config.yml

# 3. Reiniciar tunnel
sudo systemctl restart cloudflared
```

---

## ✅ Checklist de Deployment

- [ ] Migraciones de base de datos ejecutadas
- [ ] Tenant "santa_juana" creado en la tabla `public.tenants`
- [ ] Variables de entorno configuradas en Coolify
- [ ] Backend desplegado y corriendo
- [ ] Health check responde: `https://api.drozast.xyz/health`
- [ ] Cloudflare Tunnel actualizado con IP correcta del contenedor
- [ ] Registro de usuario funciona
- [ ] Login funciona
- [ ] Crear reporte funciona
- [ ] Listar reportes funciona

---

## 📚 Referencias

- **API Documentation**: `/apps/backend/API.md`
- **Infraestructura**: Ver documento que me compartiste
- **Coolify**: https://coolify.drozast.xyz
- **GitHub**: https://github.com/Drozast/frogio
- **Cloudflare Dashboard**: https://dash.cloudflare.com

---

**Última actualización**: 2024-12-14
**Estado**: Backend listo para deployment
