#!/bin/bash

# FROGIO - Script de Deployment Rápido
# Ejecutar en el servidor de producción

set -e

echo "🚀 FROGIO - Deployment Rápido"
echo "================================"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que estamos en el servidor correcto
echo "📍 Verificando servidor..."
if ! hostname | grep -q "drozast"; then
    echo -e "${YELLOW}⚠️  Warning: Este script está diseñado para drozast.xyz${NC}"
    read -p "¿Continuar de todos modos? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Deployment cancelado"
        exit 0
    fi
fi

# Verificar Docker
echo ""
echo "🐳 Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker no está instalado${NC}"
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo -e "${YELLOW}⚠️  Docker instalado. Debes cerrar sesión y volver a conectar${NC}"
    echo "Luego ejecuta nuevamente este script"
    exit 0
fi

# Verificar Git
echo ""
echo "📦 Verificando Git..."
if ! command -v git &> /dev/null; then
    echo "Instalando Git..."
    sudo apt update && sudo apt install -y git
fi

# Clonar o actualizar repositorio
echo ""
echo "📥 Obteniendo código..."
if [ -d "frogio" ]; then
    echo "Repositorio existe, actualizando..."
    cd frogio
    git pull origin main
else
    echo "Clonando repositorio..."
    git clone https://github.com/Drozast/frogio.git
    cd frogio
fi

# Generar JWT secrets si no existen
echo ""
echo "🔐 Configurando secrets..."
if [ ! -f ".env.production" ]; then
    echo "Generando JWT secrets..."
    JWT_SECRET=$(openssl rand -base64 32)
    JWT_REFRESH_SECRET=$(openssl rand -base64 32)

    cat > .env.production << EOF
# Database
DATABASE_URL=postgresql://frogio:N8H+JG/UTBQVE6G+qUJAil4n/MkLjks/o7LzMBnrU40=@192.168.31.115:5432/frogio

# API
API_URL=http://192.168.31.115:3000

# JWT Secrets
JWT_SECRET=$JWT_SECRET
JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET

# CORS
CORS_ORIGIN=http://192.168.31.115:3001

# Tenant
DEFAULT_TENANT=santa_juana
EOF

    echo -e "${GREEN}✅ Secrets generados${NC}"
else
    echo -e "${GREEN}✅ .env.production ya existe${NC}"
fi

# Deployment
echo ""
echo "🚢 Iniciando deployment..."
echo ""

# Opción de deployment
echo "Selecciona método de deployment:"
echo "1) Solo Backend + Web Admin (mínimo)"
echo "2) Backend + Web Admin + Redis"
echo "3) Backend + Web Admin + Redis + MinIO"
echo "4) Stack completo (con ntfy y monitoring)"
read -p "Opción (1-4): " deploy_option

case $deploy_option in
    1)
        echo "Deploying: Backend + Web Admin"
        docker compose -f docker-compose.prod.yml up -d
        ;;
    2)
        echo "Deploying: Backend + Web Admin + Redis"
        docker compose -f docker-compose.prod.yml --profile with-redis up -d
        ;;
    3)
        echo "Deploying: Backend + Web Admin + Redis + MinIO"
        docker compose -f docker-compose.prod.yml --profile with-redis --profile with-minio up -d
        ;;
    4)
        echo "Deploying: Stack completo"
        docker compose -f docker-compose.prod.yml \
          --profile with-redis \
          --profile with-minio \
          --profile with-ntfy \
          --profile monitoring \
          up -d
        ;;
    *)
        echo -e "${RED}❌ Opción inválida${NC}"
        exit 1
        ;;
esac

# Esperar a que los servicios inicien
echo ""
echo "⏳ Esperando a que los servicios inicien..."
sleep 10

# Verificar health
echo ""
echo "🏥 Verificando health check..."
if curl -s http://localhost:3000/health | grep -q "ok"; then
    echo -e "${GREEN}✅ Backend está funcionando!${NC}"
else
    echo -e "${RED}❌ Backend no responde${NC}"
    echo "Ver logs: docker logs frogio-backend"
    exit 1
fi

# Mostrar estado de servicios
echo ""
echo "📊 Estado de servicios:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep frogio

# URLs
echo ""
echo -e "${GREEN}🎉 Deployment completado!${NC}"
echo ""
echo "📍 URLs:"
echo "   Backend API:  http://192.168.31.115:3000"
echo "   Web Admin:    http://192.168.31.115:3001"
echo "   Health Check: http://192.168.31.115:3000/health"
echo ""
echo "👤 Usuarios de prueba:"
echo "   Admin:     admin@test.cl / admin123"
echo "   Inspector: inspector@test.cl / inspector123"
echo "   Ciudadano: ciudadano@test.cl / Admin123"
echo ""
echo "📚 Documentación:"
echo "   - DEPLOYMENT_PRODUCTION.md"
echo "   - COMANDOS_DEPLOYMENT.md"
echo "   - RESUMEN_FINAL.md"
echo ""
echo "🔧 Comandos útiles:"
echo "   Ver logs:      docker logs frogio-backend -f"
echo "   Reiniciar:     docker restart frogio-backend"
echo "   Detener todo:  docker compose -f docker-compose.prod.yml down"
echo ""
