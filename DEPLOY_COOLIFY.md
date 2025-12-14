# 🚀 FROGIO - Guía de Deploy en Coolify

## 📋 Pre-requisitos

Antes de empezar, necesitas tener:

### 1. Credenciales OAuth (Opcional pero recomendado)

**Google OAuth:**
- GOOGLE_CLIENT_ID
- GOOGLE_CLIENT_SECRET

**Facebook OAuth:**
- FACEBOOK_APP_ID
- FACEBOOK_APP_SECRET

### 2. Dominios Configurados

En Cloudflare (o tu DNS):
```
api.tudominio.com     → Tu servidor IP (A Record)
admin.tudominio.com   → Tu servidor IP (A Record)
minio.tudominio.com   → Tu servidor IP (A Record)
```

### 3. Servidor Coolify Instalado

```bash
curl -fsSL https://get.coolify.io | bash
```

---

## 🔧 Paso 1: Configurar Variables de Entorno en Coolify

En tu proyecto de Coolify, configura estas variables:

```env
# Database
DB_PASSWORD=TU_PASSWORD_SUPER_SEGURO

# MinIO
MINIO_USER=admin
MINIO_PASSWORD=TU_PASSWORD_MINIO_SEGURO

# JWT (Generar con: openssl rand -base64 32)
JWT_SECRET=TU_JWT_SECRET_MINIMO_32_CARACTERES
JWT_REFRESH_SECRET=TU_JWT_REFRESH_SECRET_MINIMO_32_CARACTERES

# API
NODE_ENV=production
API_URL=https://api.tudominio.com

# OAuth Google
GOOGLE_CLIENT_ID=tu-google-client-id
GOOGLE_CLIENT_SECRET=tu-google-client-secret
GOOGLE_CALLBACK_URL=https://api.tudominio.com/api/auth/google/callback

# OAuth Facebook
FACEBOOK_APP_ID=tu-facebook-app-id
FACEBOOK_APP_SECRET=tu-facebook-app-secret
FACEBOOK_CALLBACK_URL=https://api.tudominio.com/api/auth/facebook/callback

# SMTP (Opcional - para emails)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=tu-email@gmail.com
SMTP_PASSWORD=tu-app-password
SMTP_FROM=FROGIO <noreply@tudominio.com>

# CORS
CORS_ORIGIN=https://admin.tudominio.com,https://tudominio.com

# ntfy
NTFY_URL=http://ntfy:80
NTFY_BASE_URL=https://ntfy.tudominio.com
```

---

## 🐳 Paso 2: Deploy en Coolify

### Opción 1: Usar Docker Compose (Recomendado)

1. **Conectar repositorio Git a Coolify**
   - En Coolify: New Resource → Git Repository
   - Conecta tu repo de GitHub/GitLab

2. **Coolify detectará automáticamente** el `docker-compose.yml`

3. **Configurar variables** en la UI de Coolify

4. **Deploy!**

### Opción 2: Deploy Manual

```bash
# En tu servidor con Coolify
cd /ruta/a/tu/proyecto

# Build
docker compose build

# Deploy
docker compose up -d
```

---

## 🌐 Paso 3: Configurar Cloudflare

### SSL/TLS
- Modo: **Full (Strict)**
- Always Use HTTPS: **ON**

### DNS Records
```
Type  Name      Content          Proxy
A     api       tu-servidor-ip   ✓ (naranja)
A     admin     tu-servidor-ip   ✓
A     minio     tu-servidor-ip   ✓
```

### Firewall Rules (Opcional)
- Bloquear países no deseados
- Rate limiting

---

## 🔐 Paso 4: Inicializar Base de Datos

```bash
# Conectarse al contenedor del backend
docker exec -it frogio-backend sh

# Ejecutar migraciones
npx prisma migrate deploy

# (Opcional) Crear super admin inicial
npx tsx scripts/create-super-admin.ts
```

---

## ✅ Paso 5: Verificar Deploy

### Health Checks

```bash
# Backend API
curl https://api.tudominio.com/health

# Debería devolver:
{
  "status": "ok",
  "timestamp": "2024-12-13T...",
  "services": {
    "database": "connected",
    "redis": "connected"
  }
}
```

### Servicios

- **Backend API**: https://api.tudominio.com
- **Web Admin**: https://admin.tudominio.com
- **MinIO Console**: https://minio.tudominio.com

---

## 📊 Monitoreo

### Uptime Kuma

Accede a: `http://tu-servidor:3002`

Configura monitores para:
- Backend API (https://api.tudominio.com/health)
- Web Admin
- PostgreSQL
- Redis

---

## 🔄 Actualizaciones

### Deploy automático con Git

Coolify puede configurarse para hacer deploy automático:

1. Settings → Git
2. Activar "Deploy on push"
3. Cada push a `main` desplegará automáticamente

### Deploy manual

```bash
# En Coolify UI
Projects → Tu Proyecto → Deploy
```

---

## 🐛 Troubleshooting

### Backend no inicia

```bash
# Ver logs
docker logs frogio-backend

# Verificar variables de entorno
docker exec frogio-backend env | grep -E "DATABASE|JWT|API"
```

### Base de datos no conecta

```bash
# Verificar PostgreSQL
docker logs frogio-postgres

# Conectarse manualmente
docker exec -it frogio-postgres psql -U frogio -d frogio_production
```

### MinIO no accesible

```bash
# Ver logs
docker logs frogio-minio

# Verificar puerto
docker ps | grep minio
```

---

## 🔐 Seguridad Post-Deploy

### 1. Cambiar passwords por defecto
```bash
# MinIO
docker exec -it frogio-minio mc admin user add myminio newadmin newpassword

# PostgreSQL
docker exec -it frogio-postgres psql -U frogio
ALTER USER frogio WITH PASSWORD 'new_super_secure_password';
```

### 2. Configurar Backups Automáticos

```bash
# Backup diario a las 2 AM
crontab -e

# Agregar:
0 2 * * * cd /ruta/proyecto && ./scripts/backup.sh
```

### 3. Actualizar Firewall

```bash
# Solo permitir puertos necesarios
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw enable
```

---

## 📈 Escalabilidad

### Para alta demanda

1. **Aumentar recursos**:
   - Editar `docker-compose.yml`
   - Agregar `deploy.resources.limits`

2. **Load Balancing**:
   - Correr múltiples instancias del backend
   - Usar Traefik o Nginx como balanceador

3. **Cache**:
   - Redis ya está configurado
   - Implementar cache de queries frecuentes

---

## 📞 Support

Si algo falla:

1. Ver logs: `docker compose logs -f`
2. Verificar health: `curl https://api.tudominio.com/health`
3. Revisar variables: `docker exec frogio-backend env`

---

## ✅ Checklist de Deploy

- [ ] Variables de entorno configuradas en Coolify
- [ ] Repositorio conectado a Coolify
- [ ] DNS configurado en Cloudflare
- [ ] SSL/TLS activado
- [ ] Deploy ejecutado
- [ ] Migraciones de DB corridas
- [ ] Health check OK
- [ ] Servicios accesibles
- [ ] Backups configurados
- [ ] Monitoreo configurado

---

**¡Listo!** Tu aplicación FROGIO está en producción 🎉
