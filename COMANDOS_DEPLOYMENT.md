# 🚀 FROGIO - Comandos Rápidos de Deployment

## 📋 Conexión al Servidor

```bash
ssh drozast@192.168.31.115
```

---

## 🔧 Opción 1: Deploy con Coolify (Recomendado)

### Instalar Coolify
```bash
curl -fsSL https://get.coolify.io | bash
```

### Acceder a Coolify
Abre en tu navegador: **http://192.168.31.115:8000**

Luego sigue los pasos en **PASOS_COOLIFY.md**

---

## 🐳 Opción 2: Deploy Manual con Docker Compose

### Paso 1: Preparar Servidor

```bash
# Clonar repositorio
cd ~
git clone https://github.com/Drozast/frogio.git
cd frogio
```

### Paso 2: Generar JWT Secrets

```bash
# Generar dos secrets diferentes
openssl rand -base64 32
openssl rand -base64 32

# Copiar los valores generados para el siguiente paso
```

### Paso 3: Crear .env.production

```bash
cat > .env.production << 'EOF'
# Database
DATABASE_URL=postgresql://frogio:N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=@192.168.31.115:5432/frogio

# API
API_URL=http://192.168.31.115:3000

# JWT - Reemplazar con los valores generados arriba
JWT_SECRET=PEGAR_PRIMER_SECRET_AQUI
JWT_REFRESH_SECRET=PEGAR_SEGUNDO_SECRET_AQUI

# CORS
CORS_ORIGIN=http://192.168.31.115:3001

# DEFAULT_TENANT
DEFAULT_TENANT=santa_juana
EOF
```

### Paso 4: Deploy Solo Backend + Web Admin

```bash
# Usar docker-compose.prod.yml (sin servicios adicionales)
docker compose -f docker-compose.prod.yml up -d
```

**Tiempo de build:** 5-10 minutos

### Paso 5: Verificar Logs

```bash
# Ver logs de backend
docker logs frogio-backend -f

# Ver logs de web-admin
docker logs frogio-web-admin -f

# Ver todos los logs
docker compose -f docker-compose.prod.yml logs -f
```

### Paso 6: Verificar Health

```bash
# Health check
curl http://192.168.31.115:3000/health

# Debería retornar:
# {
#   "status": "ok",
#   "timestamp": "...",
#   "services": {
#     "database": "connected"
#   }
# }
```

---

## ✅ Verificación de Deployment

### 1. Backend API

```bash
# Health check
curl http://192.168.31.115:3000/health

# API Info
curl http://192.168.31.115:3000/api

# Probar login
curl -X POST http://192.168.31.115:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{
    "email": "admin@test.cl",
    "password": "admin123"
  }'
```

### 2. Web Admin

Abre en navegador: **http://192.168.31.115:3001/login**

Credenciales:
- **Email:** admin@test.cl
- **Password:** admin123

---

## 🔧 Deploy con Servicios Adicionales (Opcional)

### Con Redis

```bash
docker compose -f docker-compose.prod.yml --profile with-redis up -d
```

Agregar a .env.production:
```bash
REDIS_URL=redis://localhost:6379
```

### Con MinIO

```bash
docker compose -f docker-compose.prod.yml --profile with-minio up -d
```

Agregar a .env.production:
```bash
MINIO_ENDPOINT=localhost
MINIO_PORT=9000
MINIO_USE_SSL=false
MINIO_ACCESS_KEY=frogio_admin
MINIO_SECRET_KEY=frogio_secret_key_2024
MINIO_BUCKET=frogio-files
```

### Con Todos los Servicios

```bash
docker compose -f docker-compose.prod.yml \
  --profile with-redis \
  --profile with-minio \
  --profile with-ntfy \
  --profile monitoring \
  up -d
```

---

## 🔄 Actualizar Deployment

### Pull últimos cambios

```bash
cd ~/frogio
git pull origin main
```

### Rebuild y redeploy

```bash
# Detener servicios
docker compose -f docker-compose.prod.yml down

# Rebuild imágenes
docker compose -f docker-compose.prod.yml build

# Iniciar servicios
docker compose -f docker-compose.prod.yml up -d
```

### Actualizar solo backend

```bash
docker compose -f docker-compose.prod.yml up -d --build backend
```

### Actualizar solo web-admin

```bash
docker compose -f docker-compose.prod.yml up -d --build web-admin
```

---

## 📊 Comandos de Monitoreo

### Ver estado de containers

```bash
docker ps -a
```

### Ver logs en tiempo real

```bash
# Backend
docker logs frogio-backend -f

# Web Admin
docker logs frogio-web-admin -f

# Todos
docker compose -f docker-compose.prod.yml logs -f
```

### Ver uso de recursos

```bash
docker stats
```

### Ver espacio en disco

```bash
df -h
docker system df
```

---

## 🛠️ Comandos de Mantenimiento

### Reiniciar servicios

```bash
# Reiniciar backend
docker restart frogio-backend

# Reiniciar web-admin
docker restart frogio-web-admin

# Reiniciar todos
docker compose -f docker-compose.prod.yml restart
```

### Detener servicios

```bash
docker compose -f docker-compose.prod.yml down
```

### Limpiar recursos no usados

```bash
# Cuidado: esto elimina containers, imágenes y volúmenes no usados
docker system prune -a --volumes
```

### Ejecutar comandos dentro del container

```bash
# Acceder al backend
docker exec -it frogio-backend sh

# Dentro del container:
# - Ver variables: env
# - Ver archivos: ls -la
# - Salir: exit
```

---

## 🐛 Troubleshooting

### Backend no inicia

```bash
# Ver logs detallados
docker logs frogio-backend

# Verificar variables de entorno
docker exec frogio-backend env | grep -E "DATABASE|JWT"

# Reiniciar
docker restart frogio-backend
```

### Error de conexión a base de datos

```bash
# Verificar que PostgreSQL esté corriendo
sudo systemctl status postgresql

# Probar conexión directa
psql -h 192.168.31.115 -U frogio -d frogio

# Verificar DATABASE_URL en .env.production
cat .env.production | grep DATABASE_URL
```

### Puerto ya en uso

```bash
# Ver qué está usando el puerto 3000
sudo lsof -i :3000

# Matar proceso
sudo kill -9 <PID>
```

### Build falla

```bash
# Limpiar cache de Docker
docker builder prune -a

# Rebuild sin cache
docker compose -f docker-compose.prod.yml build --no-cache
```

---

## 📦 Backup de Base de Datos

### Crear backup

```bash
# Backup completo
pg_dump -h 192.168.31.115 -U frogio -d frogio > backup_$(date +%Y%m%d).sql

# Backup solo schema santa_juana
pg_dump -h 192.168.31.115 -U frogio -d frogio -n santa_juana > backup_santa_juana_$(date +%Y%m%d).sql
```

### Restaurar backup

```bash
psql -h 192.168.31.115 -U frogio -d frogio < backup_20251214.sql
```

---

## 🌐 Configurar Dominios (Opcional)

### Opción A: Nginx Reverse Proxy

```bash
# Instalar Nginx
sudo apt install nginx

# Crear configuración para backend
sudo nano /etc/nginx/sites-available/api.drozast.xyz
```

Contenido:
```nginx
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
    }
}
```

```bash
# Habilitar sitio
sudo ln -s /etc/nginx/sites-available/api.drozast.xyz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Instalar SSL
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.drozast.xyz
```

### Opción B: Cloudflare Tunnel

Ver **PASOS_COOLIFY.md** sección "Paso 10: Configurar Dominios"

---

## ✅ Checklist Post-Deployment

- [ ] Backend corriendo (`docker ps | grep backend`)
- [ ] Web-admin corriendo (`docker ps | grep web-admin`)
- [ ] Health check OK (`curl http://192.168.31.115:3000/health`)
- [ ] Login funciona en web-admin
- [ ] API login funciona (curl)
- [ ] Logs sin errores críticos
- [ ] Backups configurados
- [ ] (Opcional) Dominios configurados
- [ ] (Opcional) SSL configurado

---

## 🎯 Usuarios de Prueba

| Email | Password | Rol |
|-------|----------|-----|
| admin@test.cl | admin123 | admin |
| inspector@test.cl | inspector123 | inspector |
| ciudadano@test.cl | Admin123 | citizen |

---

## 📞 Ayuda Rápida

**Ver estado:** `docker ps`
**Ver logs:** `docker logs frogio-backend -f`
**Reiniciar:** `docker restart frogio-backend`
**Health:** `curl http://192.168.31.115:3000/health`
**Web Admin:** `http://192.168.31.115:3001/login`

---

**¡Deployment completado!** 🎉
