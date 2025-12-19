#!/bin/bash

# Script para configurar Cloudflare Tunnel en Frogio
# Uso: ./setup-cloudflare-tunnel.sh YOUR_TUNNEL_TOKEN

set -e

echo "🌐 FROGIO - Configuración de Cloudflare Tunnel"
echo "=============================================="
echo ""

# Verificar que se proporcionó el token
if [ -z "$1" ]; then
    echo "❌ Error: Debes proporcionar el token del tunnel"
    echo ""
    echo "Uso: ./setup-cloudflare-tunnel.sh YOUR_TUNNEL_TOKEN"
    echo ""
    echo "Para obtener el token:"
    echo "1. Ve a https://one.dash.cloudflare.com/"
    echo "2. Access > Tunnels > Create a tunnel"
    echo "3. Copia el token que aparece"
    exit 1
fi

TUNNEL_TOKEN=$1

echo "📝 Paso 1: Actualizando docker-compose.full.yml con el token..."

# Reemplazar el token en docker-compose.full.yml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/YOUR_CLOUDFLARE_TUNNEL_TOKEN/$TUNNEL_TOKEN/g" docker-compose.full.yml
else
    # Linux
    sed -i "s/YOUR_CLOUDFLARE_TUNNEL_TOKEN/$TUNNEL_TOKEN/g" docker-compose.full.yml
fi

echo "✅ Token configurado en docker-compose.full.yml"
echo ""

echo "📋 Paso 2: Verifica la configuración de DNS en Cloudflare"
echo ""
echo "Ve a tu dashboard de Cloudflare y agrega estos registros DNS:"
echo ""
echo "┌──────┬──────────────┬────────────────────────────────────┬────────┐"
echo "│ Type │ Name         │ Target                             │ Proxy  │"
echo "├──────┼──────────────┼────────────────────────────────────┼────────┤"
echo "│ CNAME│ api.frogio   │ UUID.cfargotunnel.com              │ Orange │"
echo "│ CNAME│ admin.frogio │ UUID.cfargotunnel.com              │ Orange │"
echo "└──────┴──────────────┴────────────────────────────────────┴────────┘"
echo ""
echo "NOTA: El UUID.cfargotunnel.com se muestra en el dashboard del tunnel"
echo ""
echo "Presiona Enter cuando hayas configurado el DNS..."
read

echo ""
echo "🚀 Paso 3: Desplegando a producción..."
echo ""

# Hacer commit del cambio
git add docker-compose.full.yml
git commit -m "chore: Configure Cloudflare Tunnel token

Added tunnel token to docker-compose for production deployment.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git push origin main

echo "✅ Cambios commiteados y pusheados"
echo ""

# Conectar al servidor y deployar
echo "📦 Desplegando en el servidor..."
echo ""

sshpass -p '123' ssh -o StrictHostKeyChecking=no drozast@192.168.31.115 << 'ENDSSH'
cd ~/frogio
git pull origin main
docker compose -f docker-compose.full.yml up -d cloudflared
echo ""
echo "⏳ Esperando 10 segundos para que el tunnel se conecte..."
sleep 10
echo ""
echo "📊 Estado del tunnel:"
docker logs frogio-cloudflared --tail 20
ENDSSH

echo ""
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================="
echo ""
echo "🧪 Próximos pasos de testing:"
echo ""
echo "1. Verificar logs del tunnel:"
echo "   ssh drozast@192.168.31.115 'docker logs frogio-cloudflared'"
echo ""
echo "2. Probar API:"
echo "   curl https://api.frogio.drozast.xyz/health"
echo ""
echo "3. Probar Web Admin:"
echo "   Abre https://admin.frogio.drozast.xyz en tu navegador"
echo ""
echo "4. Verificar en Cloudflare Dashboard que el tunnel está conectado"
echo ""
echo "📚 Documentación completa: CLOUDFLARE_TUNNEL_SETUP.md"
echo ""
