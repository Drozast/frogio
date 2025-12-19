#!/bin/bash

# FROGIO - Script de Migración a Contenedor Completo
# Este script migra de PostgreSQL del host a contenedor Docker aislado

set -e

echo "🚀 FROGIO - Migración a Contenedor Autocontenido"
echo "================================================="

# Variables
DB_PASSWORD="N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40="
BACKUP_FILE="/tmp/frogio_backup_$(date +%Y%m%d_%H%M%S).sql"

echo ""
echo "📦 Paso 1: Respaldo de base de datos actual..."
echo "----------------------------------------------"

# Exportar password para pg_dump
export PGPASSWORD="$DB_PASSWORD"

# Hacer backup de la base de datos actual
docker exec postgres pg_dump -U frogio -d frogio --clean --if-exists > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup creado exitosamente: $BACKUP_FILE"
    echo "   Tamaño: $(du -h $BACKUP_FILE | cut -f1)"
else
    echo "❌ Error al crear backup"
    exit 1
fi

echo ""
echo "🛑 Paso 2: Deteniendo servicios actuales de Frogio..."
echo "------------------------------------------------------"

# Detener contenedores actuales
docker compose -f docker-compose.prod.yml down

echo "✅ Servicios detenidos"

echo ""
echo "🏗️  Paso 3: Levantando stack completo (con PostgreSQL contenedor)..."
echo "--------------------------------------------------------------------"

# Levantar el nuevo stack completo
docker compose -f docker-compose.full.yml up -d postgres

echo "⏳ Esperando a que PostgreSQL esté listo..."
sleep 15

# Verificar que postgres esté healthy
for i in {1..30}; do
    if docker compose -f docker-compose.full.yml ps postgres | grep -q "healthy"; then
        echo "✅ PostgreSQL está listo"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Timeout esperando PostgreSQL"
        exit 1
    fi
    echo "   Intento $i/30..."
    sleep 2
done

echo ""
echo "📥 Paso 4: Restaurando datos en nuevo contenedor PostgreSQL..."
echo "---------------------------------------------------------------"

# Restaurar backup en el nuevo contenedor
cat "$BACKUP_FILE" | docker exec -i frogio-postgres psql -U frogio -d frogio

if [ $? -eq 0 ]; then
    echo "✅ Datos restaurados exitosamente"
else
    echo "❌ Error al restaurar datos"
    exit 1
fi

echo ""
echo "🚀 Paso 5: Levantando Backend y Web Admin..."
echo "--------------------------------------------"

# Levantar el resto de servicios
docker compose -f docker-compose.full.yml up -d

echo "⏳ Esperando a que todos los servicios estén listos..."
sleep 20

echo ""
echo "🔍 Paso 6: Verificando estado de servicios..."
echo "----------------------------------------------"

docker compose -f docker-compose.full.yml ps

echo ""
echo "✅ MIGRACIÓN COMPLETADA"
echo "======================"
echo ""
echo "📊 Resumen:"
echo "  - Backup guardado en: $BACKUP_FILE"
echo "  - PostgreSQL: puerto 5433 (contenedor aislado)"
echo "  - Backend API: http://192.168.31.115:3000"
echo "  - Web Admin: http://192.168.31.115:3010"
echo ""
echo "🧪 Para probar:"
echo "  curl http://192.168.31.115:3000/health"
echo ""
echo "📝 Para ver logs:"
echo "  docker compose -f docker-compose.full.yml logs -f"
echo ""
echo "🗑️  El backup se puede eliminar después de verificar:"
echo "  rm $BACKUP_FILE"
echo ""
