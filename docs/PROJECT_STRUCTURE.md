# 📂 FROGIO - Estructura del Proyecto (Monorepo)

## 🎯 Visión General

FROGIO utiliza una **arquitectura monorepo** profesional que permite:
- ✅ Compartir código entre aplicaciones
- ✅ Desarrollo independiente de cada app
- ✅ Consistencia en tipos y utilidades
- ✅ Fácil colaboración en equipos
- ✅ Build y deploy optimizados

## 📁 Estructura Completa

```
frogio_santa_juana/
│
├── apps/                          # Aplicaciones principales
│   ├── backend/                   # API Node.js + Express
│   │   ├── src/
│   │   │   ├── config/           # Configuración (env, db, redis, minio)
│   │   │   ├── middleware/       # Auth, CORS, rate limit, etc.
│   │   │   ├── modules/          # Módulos de negocio
│   │   │   │   ├── auth/         # Autenticación y usuarios
│   │   │   │   ├── reports/      # Reportes de ciudadanos
│   │   │   │   ├── infractions/  # Multas e infracciones
│   │   │   │   ├── citations/    # Citaciones al juzgado
│   │   │   │   ├── vehicles/     # Vehículos municipales
│   │   │   │   └── medical/      # Registros médicos
│   │   │   ├── shared/
│   │   │   │   ├── utils/        # Utilidades compartidas
│   │   │   │   └── validators/   # Validadores (Zod)
│   │   │   ├── database/         # Prisma client
│   │   │   └── server.ts         # Entrada principal
│   │   ├── prisma/
│   │   │   └── schema.prisma     # Schema de base de datos
│   │   ├── logs/                 # Logs (git ignored)
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── web-admin/                # Panel web Next.js
│   │   ├── src/
│   │   │   ├── app/              # App Router (Next.js 14)
│   │   │   │   ├── (auth)/       # Rutas de autenticación
│   │   │   │   ├── dashboard/    # Dashboard principal
│   │   │   │   ├── reports/      # Gestión de reportes
│   │   │   │   ├── users/        # Gestión de usuarios
│   │   │   │   ├── infractions/  # Gestión de multas
│   │   │   │   └── layout.tsx    # Layout raíz
│   │   │   ├── components/       # Componentes React
│   │   │   │   ├── ui/           # shadcn/ui components
│   │   │   │   ├── forms/        # Formularios
│   │   │   │   ├── tables/       # Tablas de datos
│   │   │   │   └── charts/       # Gráficos (Recharts)
│   │   │   ├── lib/              # Utilidades
│   │   │   │   ├── api.ts        # Cliente HTTP
│   │   │   │   ├── auth.ts       # Helpers de auth
│   │   │   │   └── utils.ts      # Utils generales
│   │   │   └── hooks/            # React Hooks
│   │   ├── public/               # Archivos estáticos
│   │   ├── Dockerfile
│   │   ├── next.config.js
│   │   ├── package.json
│   │   ├── tailwind.config.ts
│   │   └── tsconfig.json
│   │
│   └── mobile/                   # Flutter App
│       ├── lib/
│       │   ├── core/             # Core (theme, routes, utils)
│       │   ├── features/         # Features (auth, reports, etc.)
│       │   │   ├── auth/
│       │   │   ├── citizen/      # Módulo ciudadano
│       │   │   ├── inspector/    # Módulo inspector
│       │   │   └── admin/        # Módulo administrador
│       │   └── main.dart
│       ├── android/              # Proyecto Android
│       ├── ios/                  # Proyecto iOS
│       ├── web/                  # Proyecto Web
│       ├── pubspec.yaml
│       └── README.md
│
├── packages/                     # Paquetes compartidos
│   ├── shared-types/             # Tipos TypeScript compartidos
│   │   ├── src/
│   │   │   └── index.ts          # Tipos, enums, interfaces
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── shared-utils/             # Utilidades compartidas (futuro)
│   └── shared-config/            # Configuraciones compartidas (futuro)
│
├── docs/                         # Documentación
│   ├── PROJECT_STRUCTURE.md      # Este archivo
│   ├── API.md                    # Documentación de API
│   ├── DEPLOYMENT.md             # Guía de deploy
│   └── CONTRIBUTING.md           # Guía de contribución
│
├── scripts/                      # Scripts de utilidad
│   ├── setup.sh                  # Setup inicial
│   ├── backup.sh                 # Backup de DB
│   └── migrate-tenant.sh         # Migrar nuevo tenant
│
├── .github/                      # GitHub Actions (CI/CD)
│   └── workflows/
│       ├── backend.yml           # CI/CD Backend
│       ├── web-admin.yml         # CI/CD Web
│       └── mobile.yml            # CI/CD Mobile
│
├── docker-compose.yml            # Orquestación de servicios
├── .env.example                  # Variables de entorno ejemplo
├── .gitignore                    # Git ignore
├── package.json                  # Package.json raíz (workspaces)
├── turbo.json                    # Configuración Turborepo
├── README.md                     # README principal
├── ARQUITECTURA_FINAL.md         # Documentación de arquitectura
├── NEXT_STEPS.md                 # Próximos pasos
└── LICENSE                       # Licencia MIT

```

## 🔧 Tecnologías por Proyecto

### Backend (`apps/backend`)
```json
{
  "runtime": "Node.js 22",
  "framework": "Express.js",
  "language": "TypeScript",
  "database": "PostgreSQL 16 + Prisma",
  "cache": "Redis",
  "storage": "MinIO (S3-compatible)",
  "auth": "JWT + Passport.js",
  "validation": "Zod",
  "logging": "Winston"
}
```

### Web Admin (`apps/web-admin`)
```json
{
  "framework": "Next.js 14",
  "language": "TypeScript",
  "ui": "shadcn/ui + Tailwind CSS",
  "state": "Zustand",
  "forms": "React Hook Form + Zod",
  "charts": "Recharts",
  "maps": "Leaflet.js",
  "http": "Axios"
}
```

### Mobile (`apps/mobile`)
```json
{
  "framework": "Flutter 3.35+",
  "language": "Dart",
  "state": "Bloc + Cubit",
  "architecture": "Clean Architecture",
  "http": "Dio",
  "storage": "Drift (SQLite)",
  "maps": "flutter_map (Leaflet)"
}
```

### Shared Types (`packages/shared-types`)
```json
{
  "language": "TypeScript",
  "purpose": "Tipos compartidos entre backend y web",
  "exports": "User, Report, Infraction, etc."
}
```

## 📦 Gestión de Paquetes

### Workspaces (npm/pnpm/yarn)

El proyecto usa **npm workspaces** para gestionar dependencias:

```json
{
  "workspaces": [
    "apps/*",
    "packages/*"
  ]
}
```

#### Comandos comunes:

```bash
# Instalar todas las dependencias
npm install

# Instalar en un workspace específico
npm install axios --workspace=apps/backend

# Ejecutar script en un workspace
npm run dev --workspace=apps/backend
npm run dev --workspace=apps/web-admin

# Ejecutar en todos los workspaces
npm run build --workspaces

# Usar Turborepo (más rápido)
npx turbo run dev
npx turbo run build
```

## 🏗️ Flujo de Desarrollo

### 1. Setup Inicial

```bash
# Clonar proyecto
git clone <repo>
cd frogio_santa_juana

# Instalar dependencias
npm install

# Copiar .env
cp .env.example .env

# Editar .env (passwords, secrets)
nano .env

# Levantar servicios Docker
docker-compose up -d

# Inicializar base de datos
cd apps/backend
npx prisma migrate dev
```

### 2. Desarrollo Local

**Terminal 1 - Backend:**
```bash
npm run backend:dev
# o
cd apps/backend && npm run dev
```

**Terminal 2 - Web Admin:**
```bash
npm run web:dev
# o
cd apps/web-admin && npm run dev
```

**Terminal 3 - Mobile:**
```bash
cd apps/mobile
flutter run
```

### 3. Build para Producción

```bash
# Build todos los proyectos
npm run build

# Build individual
npm run backend:build
npm run web:build
cd apps/mobile && flutter build apk
```

### 4. Deploy

```bash
# Con Docker Compose
docker-compose -f docker-compose.yml up -d --build

# O en Coolify
# Conectar repo Git → Coolify detecta docker-compose.yml automáticamente
```

## 🔀 Compartir Código

### Usar tipos compartidos:

**En Backend:**
```typescript
import { User, Report, ReportStatus } from '@frogio/shared-types';

const report: Report = {
  // TypeScript autocomplete!
};
```

**En Web Admin:**
```typescript
import { User, ReportStatus } from '@frogio/shared-types';

const status: ReportStatus = ReportStatus.SUBMITTED;
```

## 📋 Convenciones

### Nombres de Archivos
- Componentes React: `PascalCase.tsx` (ej: `UserCard.tsx`)
- Utilidades: `camelCase.ts` (ej: `formatDate.ts`)
- Hooks: `use*.ts` (ej: `useAuth.ts`)
- Tipos: `*.types.ts` (ej: `user.types.ts`)

### Estructura de Commits
```bash
type(scope): mensaje

# Ejemplos:
feat(backend): add authentication module
fix(web): resolve login form validation
docs(readme): update setup instructions
chore(deps): update dependencies
```

### Branches
- `main` - Producción
- `develop` - Desarrollo
- `feature/nombre` - Nueva feature
- `fix/nombre` - Bug fix
- `release/v1.0.0` - Release

## 🧪 Testing

### Backend
```bash
cd apps/backend
npm test
```

### Web Admin
```bash
cd apps/web-admin
npm test
```

### Mobile
```bash
cd apps/mobile
flutter test
```

## 📊 Monitoreo de Estructura

### Visualizar árbol de dependencias:
```bash
npm list --depth=0 --workspaces
```

### Tamaño de paquetes:
```bash
du -sh apps/*
du -sh packages/*
```

## 🚀 Ventajas de esta Estructura

1. **Modularidad**: Cada app es independiente
2. **Reutilización**: Tipos y utils compartidos
3. **Escalabilidad**: Fácil agregar nuevas apps
4. **CI/CD**: Builds independientes por app
5. **Onboarding**: Estructura clara para nuevos devs
6. **Mantenibilidad**: Código organizado y profesional

## 👥 Para Equipos

### Asignación de Trabajo por Carpeta:

- **Equipo Backend**: `apps/backend/`
- **Equipo Frontend Web**: `apps/web-admin/`
- **Equipo Mobile**: `apps/mobile/`
- **Equipo DevOps**: `scripts/`, `docker-compose.yml`, `.github/`
- **Todos**: `packages/shared-types/`

Cada equipo puede trabajar independientemente sin colisiones!

---

**Última actualización**: Diciembre 2024
**Versión**: 1.0.0
