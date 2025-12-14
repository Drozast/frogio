# ⚡ Inicio Rápido

## 🎯 El Proyecto Tiene 2 Partes

1. **App Flutter** (funcionando ahora) → `apps/mobile/`
2. **Backend + Web** (nuevo, por implementar) → `apps/backend/` + `apps/web-admin/`

---

## 📱 Correr App Flutter (Ahora)

```bash
cd apps/mobile
flutter pub get
flutter run
```

✅ **Listo!** Tu app Flutter funciona normalmente.

---

## 🚀 Implementar Nuevo Backend (Próximo Paso)

### 1. Configurar

```bash
# Crear .env
cp .env.example .env
nano .env  # Editar: DB_PASSWORD, JWT_SECRET

# Levantar servicios Docker
docker-compose up -d
```

### 2. Inicializar

```bash
cd apps/backend

# Instalar
npm install

# Setup DB
npm run prisma:generate
npx prisma migrate dev --name init

# Correr
npm run dev
```

### 3. Acceder

- Backend API: http://localhost:3000
- Web Admin: http://localhost:3001
- MinIO: http://localhost:9001

---

## 📂 Estructura

```
frogio_santa_juana/
├── apps/mobile/      ← App Flutter ACTUAL
├── apps/backend/     ← Backend NUEVO
└── apps/web-admin/   ← Panel Web NUEVO
```

---

## 🎯 Próximos Pasos

1. Implementar autenticación en backend
2. Crear API REST (reportes, multas, etc.)
3. Migrar Flutter de Firebase a la nueva API

Ver [README.md](./README.md) para más info.
