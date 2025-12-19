# 🚀 Guía de Migración a Contenedor Completo

Esta guía migra Frogio de usar PostgreSQL del host a un stack completamente contenedor autocontenido.

## 🎯 Objetivos

- **Aislar Frogio completamente** en contenedores Docker
- **Evitar conflictos** con otros servicios del servidor (hay 30+ contenedores)
- **Incluir PostgreSQL** en el stack de Frogio
- **Mantener el mismo dominio** y URLs externas

## 📋 Antes de Empezar

### Estado Actual
```bash
frogio-backend      -> Usa PostgreSQL del host (puerto 5432)
frogio-web-admin    -> Conecta a backend
postgres (host)     -> Compartido con otros servicios
```

### Después de la Migración
```bash
frogio-postgres     -> PostgreSQL propio en puerto 5433
frogio-backend      -> Conecta a frogio-postgres (interno)
frogio-web-admin    -> Conecta a frogio-backend (interno)
Todo en red aislada: frogio_network
```

## 🔧 Cambios de Puertos

| Servicio | Puerto Anterior | Puerto Nuevo | Razón |
|----------|----------------|--------------|-------|
| PostgreSQL | 5432 (host) | 5433 (contenedor) | Evitar conflicto con postgres del host |
| Backend | 3000 | 3000 | Sin cambios |
| Web Admin | 3010 | 3010 | Sin cambios |

## 📝 Pasos de Migración

### 1. Preparar archivos en el servidor

```bash
cd ~/frogio
git pull origin main
```

### 2. Hacer el script ejecutable

```bash
chmod +x migrate-to-container.sh
```

### 3. Ejecutar migración

```bash
./migrate-to-container.sh
```

El script hace automáticamente:
1. ✅ Backup de la base de datos actual
2. ✅ Detiene servicios antiguos
3. ✅ Levanta PostgreSQL en contenedor
4. ✅ Restaura los datos
5. ✅ Levanta Backend y Web Admin
6. ✅ Verifica que todo esté funcionando

## 🧪 Verificación

### Verificar servicios corriendo

```bash
docker compose -f docker-compose.full.yml ps
```

Deberías ver:
```
NAME                STATUS              PORTS
frogio-postgres     Up (healthy)        0.0.0.0:5433->5432/tcp
frogio-backend      Up (healthy)        0.0.0.0:3000->3000/tcp
frogio-web-admin    Up (healthy)        0.0.0.0:3010->3000/tcp
```

### Probar endpoints

```bash
# Health check del backend
curl http://192.168.31.115:3000/health

# Login
curl -X POST http://192.168.31.115:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{"email":"admin@test.cl","password":"Password123!"}'
```

### Verificar datos

```bash
# Conectar a PostgreSQL del contenedor
docker exec -it frogio-postgres psql -U frogio -d frogio

# Listar usuarios
SELECT email, role FROM santa_juana.users;
```

## 🔄 Comandos Útiles

### Ver logs
```bash
# Todos los servicios
docker compose -f docker-compose.full.yml logs -f

# Solo un servicio
docker compose -f docker-compose.full.yml logs -f backend
docker compose -f docker-compose.full.yml logs -f postgres
```

### Reiniciar servicios
```bash
# Todos
docker compose -f docker-compose.full.yml restart

# Solo uno
docker compose -f docker-compose.full.yml restart backend
```

### Detener/Levantar
```bash
# Detener
docker compose -f docker-compose.full.yml down

# Levantar
docker compose -f docker-compose.full.yml up -d
```

### Rebuild después de cambios en código
```bash
docker compose -f docker-compose.full.yml up -d --build
```

## 📊 Monitoreo

### Ver estado de healthchecks
```bash
docker inspect frogio-backend --format='{{.State.Health.Status}}'
docker inspect frogio-postgres --format='{{.State.Health.Status}}'
docker inspect frogio-web-admin --format='{{.State.Health.Status}}'
```

### Uso de recursos
```bash
docker stats frogio-postgres frogio-backend frogio-web-admin
```

## 🔐 Acceso a Postgres

### Desde el host
```bash
# Puerto externo 5433
psql -h 192.168.31.115 -p 5433 -U frogio -d frogio
```

### Desde contenedores de Frogio
```bash
# Puerto interno 5432 (DNS: postgres)
# Ya configurado en DATABASE_URL
```

## 🗄️ Backups

### Backup manual
```bash
docker exec frogio-postgres pg_dump -U frogio -d frogio > backup_$(date +%Y%m%d).sql
```

### Restaurar backup
```bash
cat backup_20250101.sql | docker exec -i frogio-postgres psql -U frogio -d frogio
```

## ⚠️ Troubleshooting

### PostgreSQL no inicia
```bash
# Ver logs
docker compose -f docker-compose.full.yml logs postgres

# Verificar volumen
docker volume inspect frogio_postgres_data
```

### Backend no conecta a DB
```bash
# Verificar que postgres esté healthy
docker compose -f docker-compose.full.yml ps postgres

# Ver logs de backend
docker compose -f docker-compose.full.yml logs backend | grep -i database
```

### Conflictos de puerto
```bash
# Ver qué está usando el puerto
lsof -i :5433
lsof -i :3000
lsof -i :3010

# Cambiar puerto en docker-compose.full.yml si es necesario
```

## 🔙 Rollback (si algo sale mal)

Si necesitas volver al setup anterior:

```bash
# 1. Detener nuevo stack
docker compose -f docker-compose.full.yml down

# 2. Levantar stack antiguo
docker compose -f docker-compose.prod.yml up -d

# 3. Los datos siguen en el postgres del host
```

## 📁 Archivos Importantes

- `docker-compose.full.yml` - Stack completo con PostgreSQL
- `docker-compose.prod.yml` - Stack antiguo (sin PostgreSQL)
- `.env.production.container` - Variables de entorno para stack completo
- `migrate-to-container.sh` - Script de migración automática

## 🎯 Ventajas del Nuevo Setup

✅ **Aislamiento total** - Frogio no afecta otros servicios
✅ **Portable** - Todo en contenedores, fácil de mover
✅ **Versionado** - PostgreSQL específico para Frogio
✅ **Backups simples** - Un solo stack para respaldar
✅ **Sin conflictos** - Red propia, puertos dedicados

## 🚀 Próximos Pasos

Después de migrar exitosamente:

1. Monitorear por 24-48 horas
2. Eliminar el backup si todo funciona bien
3. Actualizar documentación del proyecto
4. Considerar agregar Traefik/Nginx Proxy Manager para HTTPS
5. Configurar backups automáticos programados
