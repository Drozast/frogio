#!/bin/bash

# ========================================
# FROGIO - Backup Script
# ========================================

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🔄 FROGIO - Backup de Base de Datos"
echo "========================================="

# Crear directorio de backups
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL
echo "Ejecutando backup de PostgreSQL..."
docker-compose exec -T postgres pg_dump -U frogio frogio_production | gzip > "$BACKUP_DIR/postgres_$TIMESTAMP.sql.gz"
echo "✅ Backup PostgreSQL completado: $BACKUP_DIR/postgres_$TIMESTAMP.sql.gz"

# Backup MinIO (opcional)
echo "Ejecutando backup de archivos MinIO..."
docker-compose exec -T minio mc mirror /data "$BACKUP_DIR/minio_$TIMESTAMP" 2>/dev/null || echo "⚠️  MinIO backup requiere configuración adicional"

# Limpiar backups antiguos (mantener últimos 7)
echo "Limpiando backups antiguos..."
ls -t "$BACKUP_DIR"/postgres_*.sql.gz | tail -n +8 | xargs -r rm
echo "✅ Backups antiguos eliminados"

echo ""
echo "✅ Backup completado!"
echo "Archivos guardados en: $BACKUP_DIR"
