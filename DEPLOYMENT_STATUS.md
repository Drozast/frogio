# 🚀 Estado del Deployment de Frogio

**Fecha:** 2025-12-19
**Estado:** ✅ OPERATIVO - Stack Completamente Contenedor
**Servidor:** 192.168.31.115

---

## 📦 Arquitectura Actual

### Stack Completo Autocontenido
Frogio ahora corre en un stack completamente aislado con todos sus servicios en contenedores:

```
┌─────────────────────────────────────────────────────┐
│              FROGIO NETWORK (Aislada)               │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐     ┌──────────────┐            │
│  │  PostgreSQL  │────▶│   Backend    │            │
│  │  :5432       │     │   :3000      │            │
│  │  (interno)   │     │   (NestJS)   │            │
│  └──────────────┘     └──────────────┘            │
│         │                     │                    │
│         │                     ▼                    │
│  [Volumen:         ┌──────────────┐               │
│   postgres_data]   │  Web Admin   │               │
│                    │   :3000      │               │
│                    │  (Next.js)   │               │
│                    └──────────────┘               │
│                                                     │
└─────────────────────────────────────────────────────┘
         │               │              │
         ▼               ▼              ▼
    Host:5433      Host:3000      Host:3010
```

## 🔌 Puertos Expuestos

| Servicio | Puerto Interno | Puerto Host | Acceso Público |
|----------|---------------|-------------|----------------|
| PostgreSQL | 5432 | 5433 | No (solo backup) |
| Backend API | 3000 | 3000 | Sí |
| Web Admin | 3000 | 3010 | Sí |

## 🌐 URLs de Acceso

- **Backend API:** http://192.168.31.115:3000
- **Health Check:** http://192.168.31.115:3000/health
- **Web Admin:** http://192.168.31.115:3010
- **PostgreSQL:** `postgresql://frogio:***@192.168.31.115:5433/frogio`

## ✅ Estado de Servicios

```bash
$ docker compose -f docker-compose.full.yml ps

NAME               STATUS              PORTS
frogio-postgres    Up (healthy)        0.0.0.0:5433->5432/tcp
frogio-backend     Up (healthy)        0.0.0.0:3000->3000/tcp
frogio-web-admin   Up (healthy)        0.0.0.0:3010->3000/tcp
```

### Healthchecks Activos

- ✅ PostgreSQL: `pg_isready` cada 10s
- ✅ Backend: HTTP GET `/health` cada 30s
- ✅ Web Admin: `wget` al root cada 30s

## 🗄️ Base de Datos

### Configuración
- **Motor:** PostgreSQL 16 Alpine
- **Usuario:** frogio
- **Base de Datos:** frogio
- **Schema:** santa_juana
- **Volumen:** frogio_postgres_data (persistente)

### Datos Migrados
```sql
✅ 3 usuarios (admin, inspector, ciudadano)
✅ 1 infracción de prueba
✅ Todos los schemas y tablas
✅ Índices y constraints
✅ Triggers y funciones
```

### Backup Automático
Último backup: `/tmp/frogio_backup_20251219_000220.sql` (36KB)

## 🔒 Seguridad

### Variables de Entorno
- ✅ JWT_SECRET configurado
- ✅ JWT_REFRESH_SECRET configurado
- ✅ DATABASE_URL con password URL-encoded
- ✅ Tenant por defecto: `santa_juana`

### Aislamiento
- ✅ Red privada `frogio_network`
- ✅ Sin acceso directo entre contenedores de Frogio y otros servicios
- ✅ PostgreSQL NO expone 5432 (usa 5433 para evitar conflictos)

## 🚀 Comandos de Gestión

### Ver Estado
```bash
cd ~/frogio
docker compose -f docker-compose.full.yml ps
```

### Ver Logs
```bash
# Todos los servicios
docker compose -f docker-compose.full.yml logs -f

# Un servicio específico
docker compose -f docker-compose.full.yml logs -f backend
docker compose -f docker-compose.full.yml logs -f postgres
```

### Reiniciar Servicios
```bash
# Todos
docker compose -f docker-compose.full.yml restart

# Solo uno
docker compose -f docker-compose.full.yml restart backend
```

### Detener/Levantar
```bash
# Detener (mantiene datos)
docker compose -f docker-compose.full.yml down

# Levantar
docker compose -f docker-compose.full.yml up -d

# Rebuild (después de cambios en código)
docker compose -f docker-compose.full.yml up -d --build
```

### Actualizar desde Git
```bash
cd ~/frogio
git pull origin main
docker compose -f docker-compose.full.yml up -d --build
```

## 💾 Backups

### Crear Backup
```bash
docker exec frogio-postgres pg_dump -U frogio -d frogio > backup_$(date +%Y%m%d).sql
```

### Restaurar Backup
```bash
cat backup_20250119.sql | docker exec -i frogio-postgres psql -U frogio -d frogio
```

### Acceso Directo a PostgreSQL
```bash
# Desde el servidor
docker exec -it frogio-postgres psql -U frogio -d frogio

# Desde fuera del servidor
psql -h 192.168.31.115 -p 5433 -U frogio -d frogio
```

## 🧪 Tests de Verificación

### 1. Backend Health
```bash
curl http://192.168.31.115:3000/health
# Expected: {"status":"ok",...}
```

### 2. Login
```bash
curl -X POST http://192.168.31.115:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{"email":"admin@test.cl","password":"Password123!"}'
# Expected: {"user":{...},"accessToken":"..."}
```

### 3. Listar Infracciones
```bash
# Primero obtener token
TOKEN=$(curl -s -X POST http://192.168.31.115:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{"email":"inspector@test.cl","password":"Password123!"}' \
  | jq -r '.accessToken')

# Luego consultar
curl -X GET http://192.168.31.115:3000/api/infractions \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: santa_juana"
```

## 📊 Monitoreo de Recursos

### Uso de CPU y Memoria
```bash
docker stats frogio-postgres frogio-backend frogio-web-admin
```

### Tamaño de Volúmenes
```bash
docker system df -v | grep frogio
```

### Red
```bash
docker network inspect frogio_network
```

## 🔍 Troubleshooting

### Backend no inicia
1. Ver logs: `docker compose -f docker-compose.full.yml logs backend`
2. Verificar DATABASE_URL en variables de entorno
3. Confirmar que PostgreSQL esté healthy

### PostgreSQL no responde
1. Ver logs: `docker compose -f docker-compose.full.yml logs postgres`
2. Verificar volumen: `docker volume inspect frogio_postgres_data`
3. Revisar healthcheck: `docker inspect frogio-postgres`

### Web Admin no carga
1. Ver logs: `docker compose -f docker-compose.full.yml logs web-admin`
2. Verificar que backend esté healthy
3. Confirmar variables NEXT_PUBLIC_API_URL

### Conflictos de Puerto
```bash
# Ver qué está usando los puertos
lsof -i :5433
lsof -i :3000
lsof -i :3010
```

## 📈 Próximas Mejoras

- [ ] Configurar backups automáticos programados
- [ ] Agregar Nginx Proxy Manager para HTTPS
- [ ] Implementar monitoreo con Uptime Kuma
- [ ] Configurar Redis para cache (opcional)
- [ ] Agregar MinIO para almacenamiento de archivos (opcional)

## 📝 Historial de Cambios

### 2025-12-19
- ✅ Migración a stack completamente contenedor
- ✅ PostgreSQL aislado en contenedor propio (puerto 5433)
- ✅ Datos migrados exitosamente desde PostgreSQL del host
- ✅ Todos los servicios healthy y funcionando
- ✅ Tests de integración pasando

### 2025-12-18
- ✅ Fix UUID casting en infracciones y reportes
- ✅ Fix healthcheck de web-admin (wget con IPv4)
- ✅ Backend y frontend funcionando con PostgreSQL del host

---

**Mantenido por:** Claude Code
**Documentación:** [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)
**Stack:** [docker-compose.full.yml](./docker-compose.full.yml)
