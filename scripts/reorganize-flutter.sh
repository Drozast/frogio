#!/bin/bash

# ========================================
# FROGIO - Reorganizar Flutter a apps/mobile
# ========================================

set -e

echo "🔄 Reorganizando Flutter a apps/mobile..."

# Crear directorio mobile
mkdir -p apps/mobile

# Mover archivos Flutter
echo "Moviendo archivos Flutter..."
mv lib apps/mobile/ 2>/dev/null || echo "lib ya movido"
mv android apps/mobile/ 2>/dev/null || echo "android ya movido"
mv ios apps/mobile/ 2>/dev/null || echo "ios ya movido"
mv web apps/mobile/ 2>/dev/null || echo "web ya movido"
mv linux apps/mobile/ 2>/dev/null || echo "linux ya movido"
mv macos apps/mobile/ 2>/dev/null || echo "macos ya movido"
mv windows apps/mobile/ 2>/dev/null || echo "windows ya movido"
mv test apps/mobile/ 2>/dev/null || echo "test ya movido"
mv assets apps/mobile/ 2>/dev/null || echo "assets ya movido"
mv pubspec.yaml apps/mobile/ 2>/dev/null || echo "pubspec.yaml ya movido"
mv pubspec.lock apps/mobile/ 2>/dev/null || echo "pubspec.lock ya movido"
mv analysis_options.yaml apps/mobile/ 2>/dev/null || echo "analysis_options.yaml ya movido"
mv .metadata apps/mobile/ 2>/dev/null || echo ".metadata ya movido"
mv devtools_options.yaml apps/mobile/ 2>/dev/null || echo "devtools_options.yaml ya movido"

# Limpiar archivos Firebase antiguos (ya no se usarán)
echo "Limpiando archivos Firebase antiguos..."
rm -rf .firebaserc 2>/dev/null || true
rm -rf firebase.json 2>/dev/null || true
rm -rf functions 2>/dev/null || true

# Crear README para mobile
cat > apps/mobile/README.md <<'EOF'
# FROGIO Mobile App

App móvil Flutter para FROGIO (iOS, Android, Web).

## Setup

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Build

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web
```

## Características

- Clean Architecture
- Bloc para state management
- Multi-plataforma (iOS, Android, Web)

---

Parte del monorepo FROGIO. Ver [README principal](../../README.md).
EOF

echo "✅ Flutter reorganizado en apps/mobile/"
echo ""
echo "Próximos pasos:"
echo "1. cd apps/mobile"
echo "2. flutter pub get"
echo "3. flutter run"
