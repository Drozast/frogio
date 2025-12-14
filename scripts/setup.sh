#!/bin/bash

# ========================================
# FROGIO - Setup Script
# ========================================

set -e

echo "🚀 FROGIO - Setup Inicial"
echo "========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar Node.js
echo -e "${YELLOW}Verificando Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado. Por favor instala Node.js 22+"
    exit 1
fi
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 22 ]; then
    echo "❌ Node.js version $NODE_VERSION detectada. Se requiere version 22+"
    exit 1
fi
echo -e "${GREEN}✅ Node.js $(node -v) instalado${NC}"

# Verificar Docker
echo -e "${YELLOW}Verificando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado"
    exit 1
fi
echo -e "${GREEN}✅ Docker $(docker -v | cut -d' ' -f3 | tr -d ',') instalado${NC}"

# Verificar Docker Compose
echo -e "${YELLOW}Verificando Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose no está instalado"
    exit 1
fi
echo -e "${GREEN}✅ Docker Compose instalado${NC}"

# Crear .env si no existe
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creando archivo .env...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ .env creado. Por favor edítalo con tus valores.${NC}"
    echo ""
    echo "⚠️  IMPORTANTE: Debes editar el archivo .env antes de continuar"
    echo "nano .env"
    echo ""
    read -p "¿Has editado el archivo .env? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Por favor edita .env y vuelve a ejecutar este script"
        exit 1
    fi
else
    echo -e "${GREEN}✅ .env ya existe${NC}"
fi

# Instalar dependencias
echo -e "${YELLOW}Instalando dependencias...${NC}"
npm install
echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# Levantar servicios Docker
echo -e "${YELLOW}Levantando servicios Docker...${NC}"
docker-compose up -d postgres redis minio
echo "Esperando a que los servicios estén listos..."
sleep 10
echo -e "${GREEN}✅ Servicios Docker levantados${NC}"

# Generar Prisma Client
echo -e "${YELLOW}Generando Prisma Client...${NC}"
cd apps/backend
npm run prisma:generate
echo -e "${GREEN}✅ Prisma Client generado${NC}"

# Ejecutar migraciones
echo -e "${YELLOW}Ejecutando migraciones de base de datos...${NC}"
npx prisma migrate dev --name init
echo -e "${GREEN}✅ Migraciones ejecutadas${NC}"

cd ../..

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✅ Setup completado!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Próximos pasos:"
echo ""
echo "1. Iniciar backend:"
echo "   npm run backend:dev"
echo ""
echo "2. Iniciar web admin:"
echo "   npm run web:dev"
echo ""
echo "3. Ver logs de Docker:"
echo "   npm run docker:logs"
echo ""
echo "4. Acceder a:"
echo "   - Backend API: http://localhost:3000"
echo "   - Web Admin: http://localhost:3001"
echo "   - MinIO Console: http://localhost:9001"
echo "   - Uptime Kuma: http://localhost:3002"
echo ""
