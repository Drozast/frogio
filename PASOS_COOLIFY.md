# 🚀 FROGIO - Pasos para Deploy con Coolify

## 📋 Pasos a Seguir

### Paso 1: Conectar al Servidor

Abre una terminal y conecta al servidor:

```bash
ssh drozast@192.168.31.115
```

---

### Paso 2: Instalar Coolify

Una vez conectado al servidor, ejecuta:

```bash
# Descargar e instalar Coolify
curl -fsSL https://get.coolify.io | bash
```

**Importante:** Si Docker no está instalado, el script de Coolify lo instalará automáticamente.

**Tiempo estimado:** 5-10 minutos

---

### Paso 3: Acceder a Coolify

1. Abre tu navegador web
2. Accede a: **http://192.168.31.115:8000**
3. Sigue el wizard de configuración inicial:
   - Crea una cuenta de admin (guarda bien las credenciales)
   - Configura el servidor local (localhost)

---

### Paso 4: Configurar Repositorio GitHub

En la interfaz de Coolify:

1. **Menú lateral:** Click en "Projects"
2. **New Project:** Click en "+ New"
3. **Project Name:** `FROGIO`
4. **Dentro del proyecto:** Click en "+ New Resource"
5. **Seleccionar:** "Public Repository"
6. **Repository URL:** `https://github.com/Drozast/frogio.git`
7. **Branch:** `main`
8. **Build Pack:** Seleccionar "Docker Compose"

---

### Paso 5: Configurar Variables de Entorno para Backend

En Coolify, dentro del servicio del backend:

**Click en "Environment Variables" y agregar:**

```env
# Database
DATABASE_URL=postgresql://frogio:N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=@192.168.31.115:5432/frogio

# API
NODE_ENV=production
PORT=3000
API_URL=http://192.168.31.115:3000

# Tenant
DEFAULT_TENANT=santa_juana

# JWT - IMPORTANTE: Generar nuevos valores
# Ejecuta en terminal: openssl rand -base64 32
JWT_SECRET=GENERAR_CON_OPENSSL_RAND_BASE64_32
JWT_REFRESH_SECRET=GENERAR_CON_OPENSSL_RAND_BASE64_32
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Redis (Opcional - comentar si no usas)
# REDIS_URL=redis://localhost:6379

# MinIO (Opcional - comentar si no usas)
# MINIO_ENDPOINT=localhost
# MINIO_PORT=9000
# MINIO_USE_SSL=false
# MINIO_ACCESS_KEY=frogio_admin
# MINIO_SECRET_KEY=frogio_secret_key_2024
# MINIO_BUCKET=frogio-files

# CORS
CORS_ORIGIN=http://192.168.31.115:3001,http://localhost:3001
```

**Para generar JWT secrets seguros:**

```bash
# En tu terminal local o en el servidor, ejecuta:
openssl rand -base64 32
openssl rand -base64 32
```

Copia los valores generados y úsalos para `JWT_SECRET` y `JWT_REFRESH_SECRET`.

---

### Paso 6: Configurar Variables para Web Admin

En Coolify, dentro del servicio web-admin:

```env
NEXT_PUBLIC_API_URL=http://192.168.31.115:3000
```

---

### Paso 7: Deploy Backend

1. En Coolify, selecciona el servicio **backend**
2. Click en **"Deploy"**
3. Espera a que termine el build (5-10 minutos)
4. Verifica logs en tiempo real para detectar errores

**Indicadores de éxito:**
- Build completado ✅
- Container corriendo ✅
- Health check OK ✅

---

### Paso 8: Deploy Web Admin

1. En Coolify, selecciona el servicio **web-admin**
2. Click en **"Deploy"**
3. Espera a que termine el build (5-10 minutos)
4. Verifica logs

---

### Paso 9: Verificar Deployment

**Backend Health Check:**

```bash
# En el servidor o en tu terminal local:
curl http://192.168.31.115:3000/health
```

**Respuesta esperada:**
```json
{
  "status": "ok",
  "timestamp": "2025-12-14T...",
  "services": {
    "database": "connected"
  }
}
```

**Probar Login API:**

```bash
curl -X POST http://192.168.31.115:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{
    "email": "admin@test.cl",
    "password": "admin123"
  }'
```

**Respuesta esperada:**
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "user": {
    "id": "...",
    "email": "admin@test.cl",
    "role": "admin"
  }
}
```

**Web Admin:**

Abre en tu navegador:
```
http://192.168.31.115:3001/login
```

Credenciales de prueba:
- Email: `admin@test.cl`
- Password: `admin123`

Deberías poder:
- ✅ Ver el formulario de login
- ✅ Iniciar sesión con éxito
- ✅ Ver el dashboard

---

### Paso 10: Configurar Dominios (Opcional)

Si quieres usar dominios en lugar de IPs:

**Opción A: Cloudflare Tunnel**

1. En el servidor, instalar cloudflared:
```bash
# En el servidor
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
```

2. Autenticar:
```bash
cloudflared tunnel login
```

3. Crear tunnel:
```bash
cloudflared tunnel create frogio
```

4. Configurar rutas:
```bash
cloudflared tunnel route dns frogio api.drozast.xyz
cloudflared tunnel route dns frogio admin.drozast.xyz
```

5. Crear archivo de configuración:
```bash
nano ~/.cloudflared/config.yml
```

Contenido:
```yaml
tunnel: <TUNNEL_ID>
credentials-file: /home/drozast/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: api.drozast.xyz
    service: http://localhost:3000
  - hostname: admin.drozast.xyz
    service: http://localhost:3001
  - service: http_status:404
```

6. Ejecutar tunnel:
```bash
cloudflared tunnel run frogio
```

**Opción B: Nginx Reverse Proxy**

Ver instrucciones detalladas en `DEPLOYMENT_PRODUCTION.md` sección "Configurar Dominio → Opción B".

---

## ✅ Checklist de Deployment

- [ ] SSH conectado al servidor
- [ ] Coolify instalado y accesible en puerto 8000
- [ ] Proyecto FROGIO creado en Coolify
- [ ] Repositorio GitHub conectado
- [ ] Variables de entorno configuradas (backend)
- [ ] Variables de entorno configuradas (web-admin)
- [ ] JWT secrets generados y configurados
- [ ] Backend deployed exitosamente
- [ ] Web-admin deployed exitosamente
- [ ] Health check backend responde OK
- [ ] Login web-admin funciona
- [ ] Test de API exitoso
- [ ] (Opcional) Dominios configurados
- [ ] (Opcional) SSL configurado

---

## 🐛 Troubleshooting

### Error: "Cannot connect to Docker daemon"

**Solución:**
```bash
# Verificar que Docker esté corriendo
sudo systemctl status docker

# Si no está activo, iniciarlo
sudo systemctl start docker

# Agregar usuario a grupo docker
sudo usermod -aG docker $USER

# Cerrar sesión y volver a conectar
exit
ssh drozast@192.168.31.115
```

### Error: "Port 3000 already in use"

**Solución:**
```bash
# Ver qué está usando el puerto
sudo lsof -i :3000

# Detener el proceso
sudo kill -9 <PID>

# O cambiar el puerto en las variables de entorno
```

### Error: Database connection failed

**Solución:**
```bash
# Verificar PostgreSQL
sudo systemctl status postgresql

# Probar conexión manual
psql -h 192.168.31.115 -U frogio -d frogio

# Verificar que DATABASE_URL sea correcto en variables de entorno
```

### Backend build falla

**Solución:**
```bash
# Ver logs detallados en Coolify UI
# O en el servidor:
docker logs <container_name>

# Verificar que todas las dependencias estén en package.json
# Verificar que Dockerfile sea correcto
```

### Web Admin muestra error de API

**Solución:**
```bash
# Verificar que NEXT_PUBLIC_API_URL apunte a la URL correcta
# Verificar que backend esté corriendo
curl http://192.168.31.115:3000/health

# Revisar CORS_ORIGIN en backend incluye la URL del web-admin
```

---

## 📞 Comandos Útiles

**Ver logs en tiempo real:**
```bash
# En Coolify UI, click en el servicio y luego en "Logs"

# O desde terminal:
docker logs -f <container_name>
```

**Reiniciar servicios:**
```bash
# Backend
docker restart frogio-backend

# Web Admin
docker restart frogio-web-admin
```

**Ver estado de containers:**
```bash
docker ps -a
```

**Ver uso de recursos:**
```bash
docker stats
```

**Ejecutar comandos dentro del container:**
```bash
# Acceder al backend
docker exec -it frogio-backend sh

# Dentro del container, puedes ejecutar:
npm run migrate
node dist/server.js
etc.
```

---

## 🎉 Próximos Pasos Después del Deploy

1. **Crear datos de prueba:**
   - Crear algunos reportes
   - Crear infracciones
   - Probar notificaciones

2. **Configurar backups:**
   - Backup de PostgreSQL
   - Backup de archivos subidos

3. **Monitoreo:**
   - Configurar Uptime monitoring
   - Alertas por email/SMS

4. **Seguridad:**
   - Cambiar passwords de prueba
   - Configurar firewall
   - SSL/HTTPS

5. **Optimización:**
   - Instalar Redis para cache
   - Configurar CDN
   - Optimizar queries

---

## 📚 Recursos Adicionales

- **Documentación Coolify:** https://coolify.io/docs
- **Docker Docs:** https://docs.docker.com
- **PostgreSQL Docs:** https://www.postgresql.org/docs/
- **Next.js Deployment:** https://nextjs.org/docs/deployment

---

**¿Necesitas ayuda?** Revisa los logs en Coolify UI o ejecuta `docker logs <container_name>`

**¡Listo para comenzar!** 🚀
