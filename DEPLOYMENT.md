# Frogio · Guía de Deploy

> Última actualización: 2026-05-05
> Servidor: `server01` (192.168.31.145, alias remoto `ssh.supertools.cl`)
> Repo GitHub: https://github.com/Drozast/frogio

Esta guía cubre el deploy de los tres componentes del producto:

| Componente | Dónde corre | Dominio | Puerto host |
|-----------|-------------|---------|-------------|
| **frogioweb** (landing pública) | container `frogioweb` | `frogio.cl`, `frogio.supertools.cl` | 3025 |
| **frogio-web-admin** (panel) | container `frogio-web-admin` | `admin-frogio.supertools.cl` | 3111 |
| **frogio-backend** (API) | container `frogio-backend` | `api-frogio.supertools.cl` | 3110 |
| **mobile** (Flutter) | dispositivos | Play Store / App Store | — |

---

## 0. Acceso al servidor

Local (misma red):
```bash
ssh drozast@192.168.31.145    # password: 123
```

Remoto (vía Cloudflare tunnel — funciona desde cualquier sitio):
```bash
sshpass -p '123' ssh \
  -o ProxyCommand="cloudflared access ssh --hostname ssh.supertools.cl" \
  -o StrictHostKeyChecking=no \
  drozast@ssh.supertools.cl
```

Requisitos en tu Mac: `brew install cloudflared sshpass`.

Rutas relevantes en el servidor:

| Ruta | Qué es |
|------|--------|
| `~/frogio/` | Clone del monorepo `Drozast/frogio`. Construye `frogio-backend` y `frogio-web-admin` desde acá. |
| `~/frogioweb/` | Copia **standalone** de la landing (no es git). Construye el container `frogioweb`. |

> ⚠️ `~/frogioweb/` no se sincroniza automáticamente con `~/frogio/frogioweb/`. Hay que copiar el archivo a mano cuando cambia (ver §2).

---

## 1. Deploy del panel admin (`frogio-web-admin`) y del backend

### 1.1 Flujo normal (cambios ya en GitHub `main`)

```bash
# En el servidor:
cd ~/frogio
git fetch origin && git pull --ff-only origin main

# Rebuild solo del componente que cambió:
docker compose build web-admin       # o: build backend
docker compose up -d --force-recreate --no-deps web-admin
```

> Usá siempre `--no-deps` y `--force-recreate` para tocar **solo** el container objetivo. `docker compose up -d web-admin` sin `--force-recreate` no recrea si la imagen ya estaba arriba con la versión vieja en memoria.

### 1.2 Verificación post-deploy

```bash
docker ps --filter name=frogio-web-admin
docker logs frogio-web-admin --tail 30
curl -s -o /dev/null -w "HTTP: %{http_code}\n" http://localhost:3111/login
# Debe responder 200
```

Para confirmar que el bundle nuevo contiene un cambio específico (ej. un nuevo componente):
```bash
docker exec frogio-web-admin sh -c \
  "grep -roh 'NombreDelComponente\\|texto-distintivo' .next/static | sort -u | head -10"
```

### 1.3 Variables de entorno

- `NEXT_PUBLIC_API_URL` se inyecta en build time vía `args` en `docker-compose.yml`.
- Si cambia, **hay que rebuildear** la imagen, no basta con reiniciar.

---

## 2. Deploy de la landing (`frogioweb`)

`~/frogioweb/` **no es git**: es una copia plana que sirve un Vite-build dentro de un nginx. El monorepo trae el `src/pages/PrivacyPolicy.tsx` actualizado, pero hay que copiarlo al directorio de build.

### 2.1 Sincronizar fuente

```bash
cd ~/frogio
git pull --ff-only origin main

# Copiar archivos modificados al directorio standalone:
cp ~/frogio/frogioweb/src/pages/PrivacyPolicy.tsx ~/frogioweb/src/pages/PrivacyPolicy.tsx
# Repetir para cualquier otro archivo de frogioweb que haya cambiado.
```

### 2.2 Rebuild + restart

```bash
cd ~/frogioweb
docker compose build --no-cache
docker compose up -d
```

### 2.3 Verificación

```bash
docker ps --filter name=frogioweb
curl -s -o /dev/null -w "HTTP: %{http_code}\n" http://localhost:3025/

# Verificar que el bundle JS contiene un texto nuevo (la página es SPA):
curl -s http://localhost:3025/ | grep -oE 'src="[^"]+\.js"' | head -1 \
  | sed 's|src="|http://localhost:3025|;s|"||' \
  | xargs -I{} curl -s {} | grep -oE '21\.719|ARCOP' | sort -u
```

`frogio.cl` (dominio principal) está bajo una **cuenta separada de Cloudflare** (`frogiodevweb@gmail.com`), con un tunnel propio (`cloudflared-frogio` container). El tunnel apunta al mismo nginx local; no hay que tocarlo en deploys normales.

---

## 3. Deploy del backend

```bash
cd ~/frogio
git pull --ff-only origin main
docker compose build backend
docker compose up -d --force-recreate --no-deps backend

# Verificar:
docker logs frogio-backend --tail 50
curl -s http://localhost:3110/health
```

Migraciones Prisma (si las hay en el commit):
```bash
docker exec frogio-backend npx prisma migrate deploy
```

---

## 4. Deploy de la app móvil (Flutter)

La app NO se despliega al servidor — se compila localmente y se sube a las stores.

### 4.1 Pre-requisitos

- Flutter SDK instalado.
- Llaves de firma Android (`apps/mobile/android/key.properties`).
- Cuenta Apple Developer + certificados (para iOS).

### 4.2 Build Android

```bash
cd apps/mobile
flutter pub get
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

Subir el `.aab` a Google Play Console → Producción → Crear nueva versión.

### 4.3 Build iOS

```bash
cd apps/mobile
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
# Abrir en Xcode:
open ios/Runner.xcworkspace
# Product → Archive → Distribute App → App Store Connect
```

### 4.4 Versión

Antes de buildear, subir `version` en `apps/mobile/pubspec.yaml`:
```yaml
version: 1.2.3+45   # 1.2.3 = versionName, 45 = versionCode/build
```

---

## 5. Workflow recomendado de cambios

1. **Local**: hacer cambios, verificar con `flutter analyze` / `tsc --noEmit`.
2. **Commit selectivo**: usar `git add <archivos>` (no `-A`). El working tree del usuario tiene cientos de archivos modificados que no deben subir todos juntos.
3. **Push**: `git push origin main` (no hay branch protection — pushea directo, o abre PR si querés revisión).
4. **Servidor**: `git pull` y rebuild del componente afectado (§1, §2 o §3).
5. **Verificar**: logs + curl de health + smoke test en navegador (`/login`, `/live-map`, `/privacidad`).
6. **App móvil**: build local y subir a stores aparte.

---

## 6. Troubleshooting

### `docker compose up -d <svc>` no recrea con la imagen nueva
Usar `--force-recreate --no-deps`:
```bash
docker compose up -d --force-recreate --no-deps web-admin
```

### "Container name already in use"
Pasa cuando hay containers viejos (`af7cfa…_frogio-postgres`). No tocar a menos que sea el container objetivo. Si es el objetivo:
```bash
docker rm -f <viejo-container>
docker compose up -d --no-deps <servicio>
```

### Cambios en `.env` no se reflejan en web-admin
`NEXT_PUBLIC_*` son variables **build-time** en Next.js. Hay que rebuildear la imagen, no basta con reiniciar:
```bash
docker compose build --no-cache web-admin
docker compose up -d --force-recreate --no-deps web-admin
```

### `frogio.cl` (dominio externo) no responde después de un cambio
El tunnel `cloudflared-frogio` corre como container separado. Verificar:
```bash
docker ps --filter name=cloudflared-frogio
docker logs cloudflared-frogio --tail 30
```

### Ver qué hay realmente en el bundle desplegado
```bash
docker exec frogio-web-admin sh -c "grep -roh 'TextoBuscado' .next/static | sort -u"
docker exec frogioweb sh -c "grep -roh 'TextoBuscado' /usr/share/nginx/html | sort -u"
```

---

## 7. Cambios desplegados el 2026-05-05

| Componente | Cambio |
|-----------|--------|
| `frogio-web-admin` | El modal SOS bloqueante ahora aparece **solo para inspectores**. Admins reciben notificación push + toast no bloqueante (esquina inferior derecha) + marcador en `/live-map`. Nuevo componente `SOSAlertToast.tsx`. |
| `frogioweb` | Política de privacidad actualizada con cumplimiento de **Ley N° 21.719** (derechos ARCOP, principios, bases legales) + Ley 19.628 + GDPR. |
| `mobile` (no desplegado al servidor — pendiente subir a stores) | Nueva pantalla `PrivacyPolicyScreen`, accesible desde Mi Perfil → "Privacidad y datos personales". Checkbox de consentimiento obligatorio en el registro. Cumplimiento Ley 21.719. |

Commit: [`08b2117`](https://github.com/Drozast/frogio/commit/08b2117) · `feat(web): role-based SOS alerts + Ley 21.719 privacy policy update`

---

## 8. Referencias rápidas

```bash
# Ver todos los containers de frogio:
docker ps --filter name=frogio

# Ver logs en vivo:
docker logs -f frogio-web-admin
docker logs -f frogioweb
docker logs -f frogio-backend

# Restart sin rebuild:
docker compose restart web-admin

# Reset completo de un servicio:
docker compose stop web-admin
docker compose rm -f web-admin
docker compose up -d --no-deps web-admin
```

URLs de monitoreo:
- Uptime Kuma: https://uptime.supertools.cl (puerto 3004)
- Cloudflare Dashboard (cuenta drozast): https://dash.cloudflare.com (account `8f1d429e9debfd3bf3e97af51e9b3af0`)
