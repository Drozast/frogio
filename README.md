# FROGIO - Sistema de Gestión de Seguridad Pública Municipal

Sistema multi-tenant para municipalidades chilenas. **100% self-hosted, $0/mes**.

---

## 📁 Estructura del Proyecto

```
frogio_santa_juana/
│
├── apps/
│   ├── backend/         → API Node.js + PostgreSQL (NUEVO - por implementar)
│   ├── web-admin/       → Panel Next.js (NUEVO - por implementar)
│   └── mobile/          → App Flutter (ACTUAL - funcionando)
│
├── packages/
│   └── shared-types/    → Tipos compartidos TypeScript
│
└── docker-compose.yml   → Servicios: PostgreSQL, Redis, MinIO, etc.
```

---

## 🚀 Inicio Rápido

### Para el proyecto Flutter actual (mobile):

```bash
cd apps/mobile
flutter pub get
flutter run
```

### Para el nuevo backend (cuando esté implementado):

```bash
# 1. Configurar entorno
cp .env.example .env
nano .env  # Editar passwords

# 2. Levantar servicios
docker-compose up -d

# 3. Iniciar backend
cd apps/backend
npm install
npm run dev
```

---

## 🎯 Estado Actual

### ✅ Funcionando:
- **Flutter Mobile App** en `apps/mobile/`
  - Clean Architecture
  - Bloc state management
  - Firebase (por migrar)

### 🚧 Por Implementar:
- **Backend Node.js** - API REST para reemplazar Firebase
- **Web Admin** - Panel administrativo Next.js
- **Migración** - De Firebase a backend propio

---

## 🏗️ Stack Tecnológico

### Mobile (Actual)
- Flutter 3.35+
- Firebase (temporalmente)
- Bloc + Clean Architecture

### Backend (Nuevo - Por Implementar)
- Node.js 22 + Express + TypeScript
- PostgreSQL 16 + Prisma
- Redis + MinIO + Socket.io

### Web (Nuevo - Por Implementar)
- Next.js 14 + React
- shadcn/ui + Tailwind CSS

---

## 📚 Documentación

- **[QUICK_START.md](./QUICK_START.md)** - Guía de inicio rápido
- **[ARQUITECTURA_FINAL.md](./ARQUITECTURA_FINAL.md)** - Arquitectura propuesta
- **[docs/PROJECT_STRUCTURE.md](./docs/PROJECT_STRUCTURE.md)** - Estructura detallada

---

## 💡 Próximos Pasos

1. **Implementar backend completo**
   - Autenticación (JWT + OAuth)
   - API REST (reports, infractions, etc.)
   - Multi-tenancy

2. **Crear web admin**
   - Dashboard
   - Gestión de usuarios
   - Reportes y estadísticas

3. **Migrar Flutter app**
   - Cambiar Firebase por API REST
   - Nuevas features (registro médico, citaciones)

---

## 🔧 Comandos Útiles

```bash
# Mobile (Flutter)
cd apps/mobile
flutter run                    # Correr app
flutter build apk             # Build Android
flutter build ios             # Build iOS

# Backend (cuando esté listo)
cd apps/backend
npm run dev                   # Desarrollo
npm run build                 # Build producción

# Web Admin (cuando esté listo)
cd apps/web-admin
npm run dev                   # Desarrollo

# Docker
docker-compose up -d          # Levantar servicios
docker-compose logs -f        # Ver logs
docker-compose down           # Parar servicios
```

---

## 💰 Costos

**$0/mes** - Todo self-hosted en tu servidor

---

## 📞 Info

- **Cliente**: Municipalidad de Santa Juana
- **Versión**: 1.0.0
- **Licencia**: MIT
