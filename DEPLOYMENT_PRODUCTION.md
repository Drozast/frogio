# 🚀 FROGIO - Deployment a Producción (drozast.xyz)

## ✅ Estado Actual

### Base de Datos
- ✅ PostgreSQL 16 corriendo en 192.168.31.115:5432
- ✅ Base de datos `frogio` creada
- ✅ Schema `santa_juana` creado con 9 tablas
- ✅ Tenant "Municipalidad de Santa Juana" registrado
- ✅ 3 usuarios de prueba creados:
  - `ciudadano@test.cl` / `citizen123` (role: citizen)
  - `inspector@test.cl` / `inspector123` (role: inspector)
  - `admin@test.cl` / `admin123` (role: admin)

### Código
- ✅ Backend 100% completo (Node.js + Express + TypeScript)
- ✅ Web Admin 100% completo (Next.js 14)
- ✅ Todo commiteado en GitHub

---

## 📋 Información del Servidor

**Servidor:** drozast.xyz
**IP:** 192.168.31.115
**Usuario SSH:** drozast

**Servicios Existentes:**
- PostgreSQL 16 (puerto 5432)
  - Database: `frogio`
  - User: `frogio`
  - Password: `N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=`

---

## 🎯 Plan de Deployment

### 1. Backend API
**URL destino:** `https://api.drozast.xyz`
**Puerto:** 3000
**Framework:** Node.js 22 + Express + TypeScript

### 2. Web Admin
**URL destino:** `https://admin.drozast.xyz`
**Puerto:** 3001
**Framework:** Next.js 14

### 3. Servicios Adicionales (Opcional)
- Redis (puerto 6379) - para cache y tokens
- MinIO (puerto 9000) - para almacenamiento de archivos
- ntfy (puerto 8080) - para notificaciones push

---

## 🔧 Opción 1: Deploy con Coolify (Recomendado)

### Paso 1: Instalar Coolify (si no está instalado)

```bash
# Conectar al servidor
ssh drozast@192.168.31.115

# Instalar Coolify
curl -fsSL https://get.coolify.io | bash

# Verificar instalación
docker --version
```

### Paso 2: Acceder a Coolify

1. Abrir navegador: `http://192.168.31.115:8000`
2. Crear cuenta de admin
3. Agregar servidor local (localhost)

### Paso 3: Crear Proyecto Backend

1. **New Resource → Docker Compose**
2. **Repository:** `https://github.com/Drozast/frogio.git`
3. **Branch:** `main`
4. **Compose File:** `docker-compose.yml`

### Paso 4: Configurar Variables de Entorno

En la sección "Environment Variables" de Coolify, agregar:

```env
# Database (Ya existe)
DATABASE_URL=postgresql://frogio:N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=@192.168.31.115:5432/frogio

# API
NODE_ENV=production
PORT=3000
API_URL=https://api.drozast.xyz

# Tenant
DEFAULT_TENANT=santa_juana

# JWT (generar nuevos con: openssl rand -base64 32)
JWT_SECRET=W9KpX7mR5qN2vL8jH4fT6yU3nB1aZ0xC9eS5wQ7dM2pG8kJ4hF6rT3vY1nL0mX9
JWT_REFRESH_SECRET=K2pL9mN4xT7wQ1vZ6jR3eY8uH5nB0aC7dS4fG2kM9pX6tL1wJ8qV5yN3rE0hU9

# Redis
REDIS_URL=redis://localhost:6379

# MinIO
MINIO_ENDPOINT=localhost
MINIO_PORT=9000
MINIO_USE_SSL=false
MINIO_ACCESS_KEY=frogio_admin
MINIO_SECRET_KEY=frogio_secret_key_2024
MINIO_BUCKET=frogio-files

# ntfy
NTFY_URL=http://localhost:8080
NTFY_BASE_URL=https://ntfy.drozast.xyz

# CORS
CORS_ORIGIN=https://admin.drozast.xyz,https://drozast.xyz

# Email (Opcional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM=FROGIO <noreply@drozast.xyz>
```

### Paso 5: Deploy Backend

1. En Coolify, click en **Deploy**
2. Esperar a que termine el build (5-10 minutos)
3. Verificar logs para errores

### Paso 6: Configurar Dominio

**Opción A: Cloudflare Tunnel**
```bash
# En el servidor
cloudflared tunnel create frogio
cloudflared tunnel route dns frogio api.drozast.xyz
cloudflared tunnel run frogio --url http://localhost:3000
```

**Opción B: Nginx Reverse Proxy**
```nginx
# /etc/nginx/sites-available/api.drozast.xyz
server {
    listen 80;
    server_name api.drozast.xyz;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Paso 7: Deploy Web Admin

Repetir pasos 3-6 pero con:
- **Puerto:** 3001
- **Dominio:** admin.drozast.xyz
- **Variables adicionales:**
```env
NEXT_PUBLIC_API_URL=https://api.drozast.xyz
```

---

## 🔧 Opción 2: Deploy Manual con Docker

### Paso 1: Clonar Repositorio

```bash
ssh drozast@192.168.31.115

cd ~
git clone https://github.com/Drozast/frogio.git
cd frogio
```

### Paso 2: Crear .env de Producción

```bash
cd apps/backend
cp .env.example .env.production

# Editar con los valores de producción
nano .env.production
```

### Paso 3: Build Backend

```bash
cd apps/backend

# Build imagen Docker
docker build -t frogio-backend:latest .

# Correr contenedor
docker run -d \
  --name frogio-backend \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env.production \
  --network host \
  frogio-backend:latest
```

### Paso 4: Build Web Admin

```bash
cd ../web-admin

# Crear .env.production
echo "NEXT_PUBLIC_API_URL=https://api.drozast.xyz" > .env.production

# Build imagen Docker
docker build -t frogio-web-admin:latest .

# Correr contenedor
docker run -d \
  --name frogio-web-admin \
  --restart unless-stopped \
  -p 3001:3000 \
  --env-file .env.production \
  frogio-web-admin:latest
```

---

## ✅ Verificación del Deploy

### 1. Health Check Backend

```bash
curl http://localhost:3000/health

# Debería retornar:
{
  "status": "ok",
  "timestamp": "2025-12-14T...",
  "services": {
    "database": "connected"
  }
}
```

### 2. Probar Login en Web Admin

```bash
# Abrir en navegador
http://localhost:3001/login

# Credenciales de prueba:
admin@test.cl / admin123
```

### 3. Probar API

```bash
# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{
    "email": "admin@test.cl",
    "password": "admin123"
  }'

# Debería retornar accessToken y refreshToken
```

### 4. Verificar Logs

```bash
# Backend
docker logs frogio-backend -f

# Web Admin
docker logs frogio-web-admin -f
```

---

## 🔐 Seguridad

### 1. Firewall (UFW)

```bash
# Si no está activo
sudo ufw enable

# Permitir puertos necesarios
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 5432/tcp  # PostgreSQL (solo desde localhost)

# Verificar status
sudo ufw status
```

### 2. SSL con Let's Encrypt (Nginx)

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obtener certificado
sudo certbot --nginx -d api.drozast.xyz -d admin.drozast.xyz

# Auto-renovación
sudo certbot renew --dry-run
```

### 3. Cambiar Secrets de Producción

**Importante:** Los JWT_SECRET en este documento son de ejemplo. Generar nuevos:

```bash
# Generar secrets
openssl rand -base64 32
openssl rand -base64 32
```

---

## 📊 Monitoreo

### Logs

```bash
# Ver todos los logs
docker compose logs -f

# Solo backend
docker logs frogio-backend -f

# Solo web-admin
docker logs frogio-web-admin -f
```

### Recursos

```bash
# Uso de recursos
docker stats

# Disco
df -h
```

---

## 🔄 Actualizaciones

```bash
# Conectar al servidor
ssh drozast@192.168.31.115

cd ~/frogio

# Pull últimos cambios
git pull origin main

# Rebuild y restart
docker compose down
docker compose build
docker compose up -d
```

---

## 🐛 Troubleshooting

### Backend no inicia

```bash
# Ver logs
docker logs frogio-backend

# Verificar variables
docker exec frogio-backend env | grep DATABASE_URL

# Reiniciar
docker restart frogio-backend
```

### Database connection error

```bash
# Verificar PostgreSQL
sudo systemctl status postgresql

# Verificar acceso
psql -h 192.168.31.115 -U frogio -d frogio

# Ver conexiones activas
SELECT * FROM pg_stat_activity WHERE datname = 'frogio';
```

### Web Admin no carga

```bash
# Ver logs
docker logs frogio-web-admin

# Verificar que backend esté corriendo
curl http://localhost:3000/health

# Reiniciar
docker restart frogio-web-admin
```

---

## 📞 Siguiente Pasos

1. ✅ Base de datos migrada
2. ⏳ Deploy backend a Coolify/Docker
3. ⏳ Deploy web-admin a Coolify/Docker
4. ⏳ Configurar dominios (api.drozast.xyz, admin.drozast.xyz)
5. ⏳ Configurar SSL
6. ⏳ Probar toda la aplicación en producción
7. ⏳ Configurar backups automáticos
8. ⏳ Configurar monitoreo

---

## ✨ URLs Finales

- **API Backend:** https://api.drozast.xyz
- **Web Admin:** https://admin.drozast.xyz
- **API Docs:** https://api.drozast.xyz/api-docs

**Usuarios de Prueba:**
- Ciudadano: `ciudadano@test.cl` / `citizen123`
- Inspector: `inspector@test.cl` / `inspector123`
- Admin: `admin@test.cl` / `admin123`
