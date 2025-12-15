#!/bin/bash

# Script para ejecutar el deployment desde tu Mac
# Este script se conectará al servidor y ejecutará el deployment

echo "🚀 FROGIO - Deployment desde Mac a Servidor"
echo "=============================================="
echo ""

SERVER="drozast@192.168.31.115"

echo "📡 Conectando a $SERVER..."
echo ""

# Verificar conectividad
if ! ssh -o ConnectTimeout=5 $SERVER 'exit' 2>/dev/null; then
    echo "❌ No se puede conectar al servidor"
    echo ""
    echo "Por favor asegúrate de:"
    echo "  1. El servidor está encendido y accesible"
    echo "  2. Puedes hacer SSH: ssh $SERVER"
    echo "  3. Tu clave SSH está configurada o tienes la contraseña"
    echo ""
    exit 1
fi

echo "✅ Conexión exitosa!"
echo ""

# Transferir y ejecutar el script de deployment
echo "📤 Transfiriendo script de deployment..."
scp DEPLOY_RAPIDO.sh $SERVER:/tmp/deploy-frogio.sh

echo ""
echo "🚀 Ejecutando deployment en el servidor..."
echo ""

ssh -t $SERVER 'bash /tmp/deploy-frogio.sh'

echo ""
echo "✅ Deployment completado!"
echo ""
echo "🌐 Accede a:"
echo "   Backend:   http://192.168.31.115:3000"
echo "   Web Admin: http://192.168.31.115:3001"
echo ""
