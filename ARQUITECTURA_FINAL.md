# FROGIO - Arquitectura 100% Self-Hosted (Costo: $0)

## 🎯 Stack Definitivo (Sin Costos)

```
┌─────────────────────────────────────────────────────────────┐
│                    COOLIFY (Tu Servidor)                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Backend    │  │   Frontend   │  │   Mobile     │      │
│  │  Node.js +   │  │   Next.js    │  │   Flutter    │      │
│  │  Express     │  │   (Admin)    │  │  (Todos)     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ PostgreSQL   │  │    MinIO     │  │    ntfy.sh   │      │
│  │  (Database)  │  │  (Storage)   │  │   (Push)     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │    Redis     │  │  Traefik     │  │   Postfix    │      │
│  │   (Cache)    │  │   (Proxy)    │  │   (Email)    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                       Cloudflare (Free)
                    (SSL + CDN + DDoS)
```

## 📦 Servicios Self-Hosted

### 1. **Backend API**
- **Node.js 22** + Express.js
- **PostgreSQL 16** (multi-tenant con schemas)
- **Prisma ORM** (migraciones automáticas)
- **JWT Auth** + OAuth2 (Google/Facebook)
- **WebSockets** (Socket.io para tiempo real)

### 2. **Frontend Web**
- **Next.js 14** (SSR)
- **shadcn/ui** + Tailwind
- **Zustand** (state)
- **Leaflet.js** (mapas gratis)

### 3. **Mobile**
- **Flutter 3.35+**
- **Bloc** (state)
- **Dio** (HTTP client)
- **flutter_map** (mapas gratis)

### 4. **Storage**
- **MinIO** (S3-compatible, 100% gratis)
- Imágenes, videos, documentos

### 5. **Notificaciones**
- **ntfy.sh** (self-hosted, push notifications)
- **Postfix** (email SMTP propio)
- **WebSockets** (notificaciones en tiempo real web)

### 6. **Caché & Performance**
- **Redis** (sesiones, cache)
- **Traefik** (reverse proxy + load balancer)

### 7. **Monitoreo**
- **Uptime Kuma** (uptime monitoring)
- **Grafana** + **Prometheus** (métricas)
- **Loki** (logs)

## 🗄️ Estructura de Base de Datos

### Multi-Tenancy: Schema per Tenant

```sql
-- Database: frogio_production

-- Schema público (compartido)
CREATE SCHEMA public;

-- Tablas globales
CREATE TABLE public.tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug VARCHAR(50) UNIQUE NOT NULL, -- 'santa-juana'
  name VARCHAR(100) NOT NULL,
  subdomain VARCHAR(50) UNIQUE,
  subscription_type VARCHAR(20) NOT NULL, -- 'monthly' | 'yearly'
  subscription_status VARCHAR(20) NOT NULL, -- 'active' | 'inactive'
  subscription_start DATE NOT NULL,
  subscription_end DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE public.super_admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Schema por municipalidad (ejemplo: santa_juana)
CREATE SCHEMA santa_juana;

-- Usuarios
CREATE TABLE santa_juana.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255),
  rut VARCHAR(12) UNIQUE NOT NULL, -- RUT chileno
  name VARCHAR(100),
  phone VARCHAR(20),
  address TEXT,
  role VARCHAR(20) NOT NULL, -- 'citizen' | 'inspector' | 'admin'
  avatar_url TEXT,
  oauth_provider VARCHAR(20), -- 'google' | 'facebook' | null
  oauth_id VARCHAR(255),
  email_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Reportes de ciudadanos
CREATE TABLE santa_juana.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  citizen_id UUID REFERENCES santa_juana.users(id),
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(50) NOT NULL,
  priority VARCHAR(20) NOT NULL DEFAULT 'medium',
  status VARCHAR(20) NOT NULL DEFAULT 'submitted',
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  address TEXT,
  assigned_to_id UUID REFERENCES santa_juana.users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Adjuntos (fotos/videos)
CREATE TABLE santa_juana.attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID REFERENCES santa_juana.reports(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_type VARCHAR(20) NOT NULL, -- 'image' | 'video'
  file_name VARCHAR(255) NOT NULL,
  file_size INTEGER,
  uploaded_at TIMESTAMP DEFAULT NOW()
);

-- Historial de estados
CREATE TABLE santa_juana.status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID REFERENCES santa_juana.reports(id) ON DELETE CASCADE,
  status VARCHAR(20) NOT NULL,
  comment TEXT,
  changed_by_id UUID REFERENCES santa_juana.users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Respuestas de inspectores/admins
CREATE TABLE santa_juana.responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID REFERENCES santa_juana.reports(id) ON DELETE CASCADE,
  responder_id UUID REFERENCES santa_juana.users(id),
  message TEXT NOT NULL,
  is_public BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Registro médico del hogar (NUEVO)
CREATE TABLE santa_juana.medical_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES santa_juana.users(id) ON DELETE CASCADE,
  household_member_name VARCHAR(100) NOT NULL,
  relationship VARCHAR(50), -- 'self' | 'spouse' | 'child' | 'parent'
  medical_condition TEXT NOT NULL,
  medications TEXT,
  emergency_contact_name VARCHAR(100),
  emergency_contact_phone VARCHAR(20),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Infracciones (multas) (NUEVO - mejorado)
CREATE TABLE santa_juana.infractions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  citation_number VARCHAR(50) UNIQUE NOT NULL,
  inspector_id UUID REFERENCES santa_juana.users(id),
  citizen_rut VARCHAR(12) NOT NULL,
  citizen_name VARCHAR(100) NOT NULL,
  infraction_type VARCHAR(100) NOT NULL,
  infraction_code VARCHAR(20),
  description TEXT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  address TEXT,
  vehicle_plate VARCHAR(10),
  payment_status VARCHAR(20) DEFAULT 'pending', -- 'pending' | 'paid' | 'overdue'
  payment_due_date DATE NOT NULL,
  paid_at TIMESTAMP,
  inspector_signature TEXT, -- Base64 o URL
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Evidencia de infracciones
CREATE TABLE santa_juana.infraction_evidence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  infraction_id UUID REFERENCES santa_juana.infractions(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_type VARCHAR(20) NOT NULL,
  uploaded_at TIMESTAMP DEFAULT NOW()
);

-- Citaciones al juzgado (NUEVO)
CREATE TABLE santa_juana.court_citations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  citation_number VARCHAR(50) UNIQUE NOT NULL,
  infraction_id UUID REFERENCES santa_juana.infractions(id),
  citizen_id UUID REFERENCES santa_juana.users(id),
  citizen_rut VARCHAR(12) NOT NULL,
  citizen_name VARCHAR(100) NOT NULL,
  court_date TIMESTAMP NOT NULL,
  court_location VARCHAR(200) NOT NULL,
  reason TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- 'pending' | 'notified' | 'attended' | 'missed'
  notification_sent_at TIMESTAMP,
  attended_at TIMESTAMP,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Vehículos municipales
CREATE TABLE santa_juana.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plate VARCHAR(10) UNIQUE NOT NULL,
  brand VARCHAR(50) NOT NULL,
  model VARCHAR(50) NOT NULL,
  year INTEGER NOT NULL,
  vehicle_type VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'available',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Logs de vehículos
CREATE TABLE santa_juana.vehicle_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID REFERENCES santa_juana.vehicles(id),
  inspector_id UUID REFERENCES santa_juana.users(id),
  action_type VARCHAR(50) NOT NULL,
  odometer_start INTEGER,
  odometer_end INTEGER,
  fuel_level DECIMAL(5, 2),
  notes TEXT,
  started_at TIMESTAMP NOT NULL,
  ended_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Notificaciones
CREATE TABLE santa_juana.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES santa_juana.users(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(50) NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_users_email ON santa_juana.users(email);
CREATE INDEX idx_users_rut ON santa_juana.users(rut);
CREATE INDEX idx_reports_citizen ON santa_juana.reports(citizen_id);
CREATE INDEX idx_reports_status ON santa_juana.reports(status);
CREATE INDEX idx_reports_assigned ON santa_juana.reports(assigned_to_id);
CREATE INDEX idx_infractions_citizen_rut ON santa_juana.infractions(citizen_rut);
CREATE INDEX idx_infractions_payment_status ON santa_juana.infractions(payment_status);
CREATE INDEX idx_court_citations_citizen_rut ON santa_juana.court_citations(citizen_rut);
CREATE INDEX idx_notifications_user ON santa_juana.notifications(user_id, read);
```

## 🔐 Sistema de Autenticación

### JWT + OAuth2 (Sin Firebase)

```typescript
// Flujo de autenticación:

1. Email/Password:
   - POST /api/auth/register
   - POST /api/auth/login
   - Devuelve: { accessToken, refreshToken, user }

2. OAuth (Google/Facebook):
   - GET /api/auth/google
   - Redirect a Google OAuth
   - Callback: GET /api/auth/google/callback
   - Devuelve: { accessToken, refreshToken, user }

3. Tokens:
   - Access Token: 15 minutos (JWT)
   - Refresh Token: 7 días (almacenado en Redis)

4. Refresh:
   - POST /api/auth/refresh
   - Body: { refreshToken }
   - Devuelve nuevo accessToken
```

## 📁 Estructura del Proyecto

```
frogio/
├── backend/                 # Node.js API
│   ├── src/
│   │   ├── config/         # Configuración
│   │   ├── middleware/     # Auth, CORS, etc.
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   ├── users/
│   │   │   ├── reports/
│   │   │   ├── infractions/
│   │   │   ├── citations/
│   │   │   ├── vehicles/
│   │   │   └── medical/
│   │   ├── shared/         # Utils, validators
│   │   ├── database/       # Prisma schema
│   │   └── server.ts
│   ├── prisma/
│   │   └── schema.prisma
│   ├── Dockerfile
│   └── package.json
│
├── web-admin/              # Next.js Admin Panel
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   ├── lib/
│   │   └── hooks/
│   ├── Dockerfile
│   └── package.json
│
├── mobile/                 # Flutter App
│   ├── lib/
│   │   ├── core/
│   │   ├── features/
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
└── docker-compose.yml      # Para Coolify
```

## 🐳 Docker Compose (Coolify)

```yaml
version: '3.8'

services:
  # PostgreSQL
  postgres:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: frogio_production
      POSTGRES_USER: frogio
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    networks:
      - frogio_network

  # Redis
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - frogio_network

  # MinIO (S3)
  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data
    environment:
      MINIO_ROOT_USER: ${MINIO_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_PASSWORD}
    ports:
      - "9000:9000"
      - "9001:9001"
    networks:
      - frogio_network

  # Backend API
  backend:
    build: ./backend
    depends_on:
      - postgres
      - redis
      - minio
    environment:
      DATABASE_URL: postgresql://frogio:${DB_PASSWORD}@postgres:5432/frogio_production
      REDIS_URL: redis://redis:6379
      MINIO_ENDPOINT: minio:9000
      MINIO_ACCESS_KEY: ${MINIO_USER}
      MINIO_SECRET_KEY: ${MINIO_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      JWT_REFRESH_SECRET: ${JWT_REFRESH_SECRET}
    ports:
      - "3000:3000"
    networks:
      - frogio_network

  # Web Admin
  web-admin:
    build: ./web-admin
    depends_on:
      - backend
    environment:
      NEXT_PUBLIC_API_URL: https://api.frogio.cl
    ports:
      - "3001:3000"
    networks:
      - frogio_network

  # ntfy (Push Notifications)
  ntfy:
    image: binwiederhier/ntfy:latest
    command: serve
    volumes:
      - ntfy_data:/var/cache/ntfy
    ports:
      - "8080:80"
    networks:
      - frogio_network

  # Uptime Kuma (Monitoring)
  uptime-kuma:
    image: louislam/uptime-kuma:1
    volumes:
      - uptime_data:/app/data
    ports:
      - "3002:3001"
    networks:
      - frogio_network

volumes:
  postgres_data:
  redis_data:
  minio_data:
  ntfy_data:
  uptime_data:

networks:
  frogio_network:
    driver: bridge
```

## 🌐 Configuración Cloudflare

```
DNS Records:
- frogio.cl                  → Tu servidor IP (A Record)
- api.frogio.cl             → Tu servidor IP (A Record)
- admin.frogio.cl           → Tu servidor IP (A Record)
- santa-juana.frogio.cl     → Tu servidor IP (A Record)
- minio.frogio.cl           → Tu servidor IP (A Record)

SSL/TLS: Full (Strict)
Firewall: Medium
Cache: Standard
```

## 💸 Costos Totales: $0/mes

✅ **Todo self-hosted en tu servidor**
✅ **Sin dependencias de terceros pagados**
✅ **Escalable a 50+ municipalidades**
✅ **Control total de los datos**

## 🚀 ¿Empezamos?

Voy a crear:
1. Backend completo (Node.js + Prisma + PostgreSQL)
2. Docker Compose para Coolify
3. Nuevo proyecto Flutter optimizado
4. Panel web Next.js

¿Procedo?
