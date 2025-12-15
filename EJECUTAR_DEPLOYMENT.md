# 🚀 EJECUTAR DEPLOYMENT - Guía de 1 Minuto

## Opción 1: Script Automático (Recomendado)

Abre una terminal y ejecuta estos comandos:

```bash
# 1. Conectar al servidor
ssh drozast@192.168.31.115

# 2. Ejecutar script de deployment
bash <(curl -fsSL https://raw.githubusercontent.com/Drozast/frogio/main/DEPLOY_RAPIDO.sh)
```

**Eso es todo!** El script te guiará paso a paso.

---

## Opción 2: Comandos Manuales (5 minutos)

Si prefieres hacerlo manual:

```bash
# 1. Conectar al servidor
ssh drozast@192.168.31.115

# 2. Instalar Docker (si no está instalado)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Cerrar sesión y volver a conectar si instaló Docker

# 3. Clonar repositorio
git clone https://github.com/Drozast/frogio.git
cd frogio

# 4. Generar secrets y crear .env.production
cat > .env.production << 'EOF'
DATABASE_URL=postgresql://frogio:N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=@192.168.31.115:5432/frogio
API_URL=http://192.168.31.115:3000
JWT_SECRET=$(openssl rand -base64 32)
JWT_REFRESH_SECRET=$(openssl rand -base64 32)
CORS_ORIGIN=http://192.168.31.115:3001
DEFAULT_TENANT=santa_juana
EOF

# 5. Deploy (opción mínima: Backend + Web Admin)
docker compose -f docker-compose.prod.yml up -d

# 6. Verificar que funciona
curl http://localhost:3000/health
```

---

## Opción 3: Desde Tu Mac (Script Local)

Ejecuta esto desde tu Mac (en el directorio del proyecto):

```bash
cd /Users/drozast/Desktop/frogio_santa_juana

# Esto te conectará y ejecutará el deployment automáticamente
ssh drozast@192.168.31.115 'bash -s' < DEPLOY_RAPIDO.sh
```

---

## ¿Qué hace el script automático?

1. ✅ Verifica que Docker esté instalado (lo instala si no)
2. ✅ Clona el repositorio de GitHub
3. ✅ Genera JWT secrets seguros automáticamente
4. ✅ Te pregunta qué servicios quieres:
   - Opción 1: Solo Backend + Web Admin (mínimo)
   - Opción 2: + Redis
   - Opción 3: + Redis + MinIO
   - Opción 4: Stack completo con ntfy y monitoring
5. ✅ Hace el deployment con Docker Compose
6. ✅ Verifica que el backend responda
7. ✅ Muestra las URLs y credenciales

---

## Después del Deployment

### Verificar que funciona:

```bash
# Health check
curl http://192.168.31.115:3000/health

# Debería retornar:
# {"status":"ok","timestamp":"...","services":{"database":"connected"}}
```

### Acceder a la aplicación:

1. **Web Admin:** http://192.168.31.115:3001/login
   - Usuario: `admin@test.cl`
   - Password: `admin123`

2. **API Backend:** http://192.168.31.115:3000
   - Endpoint de prueba: http://192.168.31.115:3000/api

### Ver logs:

```bash
# Backend
docker logs frogio-backend -f

# Web Admin
docker logs frogio-web-admin -f

# Todos los servicios
docker compose -f docker-compose.prod.yml logs -f
```

---

## Comandos Útiles Post-Deployment

```bash
# Ver estado de servicios
docker ps

# Reiniciar backend
docker restart frogio-backend

# Reiniciar web-admin
docker restart frogio-web-admin

# Detener todo
docker compose -f docker-compose.prod.yml down

# Actualizar código
cd frogio
git pull origin main
docker compose -f docker-compose.prod.yml up -d --build
```

---

## Si algo falla

### Backend no inicia:
```bash
docker logs frogio-backend
```

### Web Admin no carga:
```bash
docker logs frogio-web-admin
```

### Database no conecta:
```bash
# Verificar PostgreSQL
psql -h 192.168.31.115 -U frogio -d frogio
```

---

## Resumen de 1 Línea

**Para deployment más rápido:**

```bash
ssh drozast@192.168.31.115 "bash <(curl -fsSL https://raw.githubusercontent.com/Drozast/frogio/main/DEPLOY_RAPIDO.sh)"
```

**¡Listo!** 🎉

---

## Soporte

Si necesitas ayuda:
- Ver: [DEPLOYMENT_PRODUCTION.md](DEPLOYMENT_PRODUCTION.md)
- Ver: [COMANDOS_DEPLOYMENT.md](COMANDOS_DEPLOYMENT.md)
- Ver: [RESUMEN_FINAL.md](RESUMEN_FINAL.md)
