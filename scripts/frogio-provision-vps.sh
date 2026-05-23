#!/bin/bash
# ===============================================
# FROGIO — Provisioning de VPS nuevo por municipio
# Para: Ubuntu 18.04+ LTS
# 
# Arquitectura:
#   - 1 VPS por municipio = SOLO API (backend)
#   - Web-admin centralizado en frogio.cl/[tenant]
#   - App Flutter con flavors (--dart-define TENANT_ID)
# ===============================================
set -e

if [ $# -lt 3 ]; then
  echo "Uso: $0 <tenant_id> <puerto_api> <nombre_municipio>"
  echo "Ej:  $0 coronel 3100 \"Coronel\""
  exit 1
fi

TENANT=$1
API_PORT=$2
NAME=$3
DB_PASS=FrogioDB2024

echo "=========================================="
echo "  FROGIO VPS Provisioning: $NAME"
echo "  Tenant: $TENANT | API: $API_PORT"
echo "  Web: frogio.cl/$TENANT (centralizado)"
echo "=========================================="

export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/node20/bin:$PATH

# ─── 1. DEPENDENCIAS ─────────────────────────
echo ""
echo "[1/5] Instalando dependencias..."
apt-get update -qq 2>/dev/null
apt-get install -y -qq postgresql postgresql-client redis-server nginx git 2>/dev/null

if ! id postgres >/dev/null 2>&1; then
  useradd -r -s /bin/bash -d /var/lib/postgresql postgres
  mkdir -p /var/lib/postgresql && chown postgres:postgres /var/lib/postgresql
fi
if ! pg_lsclusters 2>/dev/null | grep -q "10.*main"; then
  pg_createcluster 10 main 2>/dev/null
fi
pg_ctlcluster 10 main start 2>/dev/null
su - postgres -c "psql -c \"ALTER USER postgres PASSWORD '$DB_PASS';\"" 2>/dev/null
su - postgres -c "psql -c \"CREATE USER frogio WITH PASSWORD '$DB_PASS' CREATEDB;\"" 2>/dev/null
redis-server --daemonize yes --port 6379 2>/dev/null
echo "  ✓ PostgreSQL + Redis + Nginx"

# ─── 2. NODE.JS 20 ───────────────────────────
echo ""
echo "[2/5] Instalando Node.js 20..."
if [ ! -f /usr/local/node20/bin/node ]; then
  cd /tmp
  curl -sSL "https://unofficial-builds.nodejs.org/download/release/v20.12.2/node-v20.12.2-linux-x64-glibc-217.tar.gz" -o node.tar.gz
  tar xzf node.tar.gz
  mv node-v20.12.2-linux-x64-glibc-217 /usr/local/node20
  rm node.tar.gz
  echo "export PATH=/usr/local/node20/bin:\$PATH" >> /root/.bashrc
fi
npm install -g pm2 2>/dev/null
echo "  ✓ Node $(node --version) + PM2"

# ─── 3. CLONAR / BUILD BACKEND ───────────────
echo ""
echo "[3/5] Clonando y build FROGIO backend..."
if [ ! -d /opt/frogio ]; then
  cd /opt
  git clone https://github.com/Drozast/frogio.git frogio 2>/dev/null
else
  cd /opt/frogio && git pull --ff-only origin main 2>/dev/null
fi
cd /opt/frogio/apps/backend
npm install --silent 2>/dev/null
npx prisma generate 2>/dev/null
npm run build 2>/dev/null
echo "  ✓ Build backend"

# ─── 4. BASE DE DATOS ────────────────────────
echo ""
echo "[4/5] Creando base de datos..."
su - postgres -c "psql -c \"CREATE DATABASE frogio_$TENANT OWNER frogio;\"" 2>/dev/null
cat > .env << ENVEOF
NODE_ENV=production
PORT=$API_PORT
API_URL=http://localhost:$API_PORT
DATABASE_URL=postgresql://frogio:$DB_PASS@localhost:5432/frogio_$TENANT
REDIS_URL=redis://localhost:6379
JWT_SECRET=frogio-vps-jwt-$TENANT-seguro-32caracteres
JWT_REFRESH_SECRET=frogio-vps-jwt-refresh-$TENANT-seguro-32
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=365d
CORS_ORIGIN=*
ENVEOF
npx prisma migrate deploy 2>/dev/null
echo "  ✓ DB frogio_$TENANT + migraciones"

# ─── 5. PM2 + NGINX ──────────────────────────
echo ""
echo "[5/5] Arrancando API + Nginx..."
pm2 start dist/server.js --name frogio-$TENANT-api --time 2>/dev/null
pm2 save --silent 2>/dev/null

rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/frogio-$TENANT << NGINXEOF
server {
    listen 80;
    server_name _;
    location / { proxy_pass http://localhost:$API_PORT; proxy_http_version 1.1; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; }
    location /health { proxy_pass http://localhost:$API_PORT/health; }
}
NGINXEOF
ln -sf /etc/nginx/sites-available/frogio-$TENANT /etc/nginx/sites-enabled/frogio-$TENANT
nginx -t 2>/dev/null && nginx -s reload 2>/dev/null || nginx 2>/dev/null
echo "  ✓ API en puerto $API_PORT + Nginx"

# ─── FINAL ───────────────────────────────────
echo ""
echo "=========================================="
echo "  ✅ VPS FROGIO-$NAME PROVISIONADO (API)"
echo "=========================================="
echo "  API:      http://localhost:$API_PORT/health"
echo "  Web:      frogio.cl/$TENANT (centralizado)"
echo "  PM2:      pm2 list"
echo "  Cloudflare Tunnel:"
echo "    cloudflared tunnel create frogio-$TENANT"
echo "    cloudflared tunnel route dns frogio-$TENANT api-$TENANT.supertools.cl"
echo "=========================================="
sleep 3
curl -s http://localhost:$API_PORT/health
echo ""
echo "[1/6] Instalando dependencias..."
apt-get update -qq 2>/dev/null
apt-get install -y -qq postgresql postgresql-client redis-server nginx git 2>/dev/null

# PostgreSQL
if ! id postgres >/dev/null 2>&1; then
  useradd -r -s /bin/bash -d /var/lib/postgresql postgres
  mkdir -p /var/lib/postgresql && chown postgres:postgres /var/lib/postgresql
fi
if ! pg_lsclusters 2>/dev/null | grep -q "10.*main"; then
  pg_createcluster 10 main 2>/dev/null
fi
pg_ctlcluster 10 main start 2>/dev/null
su - postgres -c "psql -c \"ALTER USER postgres PASSWORD '$DB_PASS';\"" 2>/dev/null
su - postgres -c "psql -c \"CREATE USER frogio WITH PASSWORD '$DB_PASS' CREATEDB;\"" 2>/dev/null

# Redis
redis-server --daemonize yes --port 6379 2>/dev/null

echo "  ✓ PostgreSQL + Redis + Nginx"

# ─── 2. NODE.JS 20 ───────────────────────────
echo ""
echo "[2/6] Instalando Node.js 20..."
if [ ! -f /usr/local/node20/bin/node ]; then
  cd /tmp
  curl -sSL "https://unofficial-builds.nodejs.org/download/release/v20.12.2/node-v20.12.2-linux-x64-glibc-217.tar.gz" -o node.tar.gz
  tar xzf node.tar.gz
  mv node-v20.12.2-linux-x64-glibc-217 /usr/local/node20
  rm node.tar.gz
  echo "export PATH=/usr/local/node20/bin:\$PATH" >> /root/.bashrc
fi
npm install -g pm2 2>/dev/null
echo "  ✓ Node $(node --version) + PM2 $(pm2 --version 2>/dev/null)"

# ─── 3. CLONAR / BUILD ───────────────────────
echo ""
echo "[3/6] Clonando y build FROGIO..."
if [ ! -d /opt/frogio ]; then
  cd /opt
  git clone https://github.com/Drozast/frogio.git frogio 2>/dev/null
fi
cd /opt/frogio/apps/backend
npm install --silent 2>/dev/null
npx prisma generate 2>/dev/null
npm run build 2>/dev/null

cd /opt/frogio/apps/web-admin
npm install --silent 2>/dev/null
cat > .env.local << ENVEOF
NEXT_PUBLIC_API_URL=http://localhost:$API_PORT
NEXT_PUBLIC_TENANT_ID=$TENANT
NEXT_PUBLIC_APP_NAME=FROGIO - $NAME
ENVEOF
npm run build 2>/dev/null
echo "  ✓ Build completo"

# ─── 4. BASE DE DATOS ────────────────────────
echo ""
echo "[4/6] Creando base de datos..."
su - postgres -c "psql -c \"CREATE DATABASE frogio_$TENANT OWNER frogio;\"" 2>/dev/null
cd /opt/frogio/apps/backend
cat > .env << ENVEOF
NODE_ENV=production
PORT=$API_PORT
API_URL=http://localhost:$API_PORT
DATABASE_URL=postgresql://frogio:$DB_PASS@localhost:5432/frogio_$TENANT
REDIS_URL=redis://localhost:6379
JWT_SECRET=frogio-vps-jwt-$TENANT-seguro-32caracteres
JWT_REFRESH_SECRET=frogio-vps-jwt-refresh-$TENANT-seguro-32
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=365d
CORS_ORIGIN=*
ENVEOF
npx prisma migrate deploy 2>/dev/null
echo "  ✓ DB frogio_$TENANT + migraciones"

# ─── 5. PM2 ──────────────────────────────────
echo ""
echo "[5/6] Arrancando servicios..."
cd /opt/frogio/apps/backend
pm2 start dist/server.js --name frogio-$TENANT-api --time 2>/dev/null

cd /opt/frogio/apps/web-admin
pm2 start npm --name frogio-$TENANT-web -- run start -- -p $WEB_PORT 2>/dev/null

pm2 save --silent 2>/dev/null
echo "  ✓ PM2: frogio-$TENANT-api + frogio-$TENANT-web"

# ─── 6. NGINX ────────────────────────────────
echo ""
echo "[6/6] Configurando Nginx..."
rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/frogio-$TENANT << NGINXEOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:$WEB_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /api {
        proxy_pass http://localhost:$API_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /health {
        proxy_pass http://localhost:$API_PORT/health;
    }
}
NGINXEOF
ln -sf /etc/nginx/sites-available/frogio-$TENANT /etc/nginx/sites-enabled/frogio-$TENANT
nginx -t 2>/dev/null && nginx -s reload 2>/dev/null || nginx 2>/dev/null
echo "  ✓ Nginx configurado"

# ─── FINAL ───────────────────────────────────
echo ""
echo "=========================================="
echo "  ✅ VPS FROGIO-$NAME PROVISIONADO"
echo "=========================================="
echo "  API:    http://localhost:$API_PORT/health"
echo "  Web:    http://localhost:$WEB_PORT/login"
echo "  Nginx:  http://localhost"
echo "  PM2:    pm2 list"
echo ""
echo "  Para Cloudflare Tunnel:"
echo "  cloudflared tunnel create frogio-$TENANT"
echo "=========================================="

# Verificación
sleep 3
curl -s http://localhost:$API_PORT/health
echo ""
