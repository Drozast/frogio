#!/bin/bash

# FROGIO - Script de instalación de Coolify en drozast.xyz
# Ejecutar este script EN EL SERVIDOR de producción

set -e

echo "🚀 FROGIO - Instalación de Coolify"
echo "==================================="
echo ""
echo "Servidor: drozast.xyz (192.168.31.115)"
echo ""

# Verificar si ya está instalado Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker ya está instalado:"
    docker --version
else
    echo "📦 Instalando Docker..."
    curl -fsSL https://get.docker.com | sh

    # Agregar usuario actual a grupo docker
    sudo usermod -aG docker $USER
    echo "✅ Docker instalado correctamente"
    echo "⚠️  IMPORTANTE: Debes cerrar sesión y volver a conectar para que los cambios surtan efecto"
    echo "   Luego ejecuta nuevamente este script"
    exit 0
fi

echo ""

# Verificar si ya está instalado Coolify
if docker ps -a | grep -q coolify; then
    echo "✅ Coolify ya está instalado"
    echo ""
    echo "🌐 Accede a Coolify en:"
    echo "   http://192.168.31.115:8000"
    echo ""
else
    echo "📦 Instalando Coolify..."
    echo ""

    # Instalar Coolify
    curl -fsSL https://get.coolify.io | bash

    echo ""
    echo "✅ Coolify instalado correctamente!"
    echo ""
    echo "🌐 Accede a Coolify en:"
    echo "   http://192.168.31.115:8000"
    echo ""
    echo "📋 Próximos pasos:"
    echo "   1. Abre http://192.168.31.115:8000 en tu navegador"
    echo "   2. Crea una cuenta de admin"
    echo "   3. Sigue las instrucciones en DEPLOYMENT_PRODUCTION.md"
    echo ""
fi

# Verificar servicios corriendo
echo "📊 Estado de servicios:"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Verificar espacio en disco
echo "💾 Espacio en disco:"
df -h / | grep -v Filesystem
echo ""

echo "✅ Todo listo para proceder con el deployment!"
echo ""
echo "📖 Lee DEPLOYMENT_PRODUCTION.md para los siguientes pasos"
