# FROGIO — Accesos, Credenciales y Configuración

> Última actualización: 2026-05-23
> Responsable: Damián Rozas (Rozas Digital SpA)

---

## 1. SERVIDORES

### server01 (Principal — Santa Juana + otros proyectos)

| Propiedad | Valor |
|-----------|-------|
| **Hostname** | server01 |
| **OS** | Ubuntu 25.10 |
| **IP Local** | 192.168.31.145 |
| **CPU** | Intel Xeon E5-2696 v4 — 22 cores / 44 threads |
| **RAM** | 64 GB DDR4 |
| **GPU** | NVIDIA RTX 3060 Ti 8GB |

**Acceso SSH:**
```bash
# Local (misma red)
ssh drozast@192.168.31.145        # password: 123

# Remoto (Cloudflare Tunnel)
sshpass -p '123' ssh -o ProxyCommand="cloudflared access ssh --hostname ssh.supertools.cl" -o StrictHostKeyChecking=no drozast@ssh.supertools.cl
```

### VPS Ñuñoa (frogio-ssh.supertools.cl)

| Propiedad | Valor |
|-----------|-------|
| **CPU** | 44 cores |
| **RAM** | 60 GB |
| **Disco** | 914 GB (462 GB libre) |
| **OS** | Ubuntu 18.04 LTS |

**Acceso SSH:**
```bash
sshpass -p 'Enanitos123$' ssh -o ProxyCommand="cloudflared access ssh --hostname frogio-ssh.supertools.cl" -o StrictHostKeyChecking=no root@frogio-ssh.supertools.cl
```

---

## 2. CLOUDFLARE

### Cuenta Principal — drozast

| Campo | Valor |
|-------|-------|
| **Account ID** | `8f1d429e9debfd3bf3e97af51e9b3af0` |
| **API Token (limitado)** | Ver engram: `cf-token-drozast` |
| **API Token (Global)** | Ver engram: `cf-global-token-drozast` |
| **Tunnel ID** | `804e80c5-881c-4ad0-963a-42549223c4f6` |
| **Dashboard** | https://dash.cloudflare.com |

**Dominios:**
- `supertools.cl` (ZONE_ID: `310ccb854ce65edab14fde720d4e8f28`)
- DNS Edit Token supertools.cl: Ver engram: `cf-dns-token-supertools`

### Cuenta FROGIO.cl (cuenta separada)

| Campo | Valor |
|-------|-------|
| **Account ID** | `bb907cb77668153e43379d32aa848212` |
| **Tunnel ID** | `b37abf48-fd37-475e-973f-62e4c8f8ca23` |
| **Container** | `cloudflared-frogio` en server01 |

> ⚠️ Esta cuenta NO está bajo el control de drozast. El túnel corre en server01 vía container con token directo. La gestión de rutas es remota (Cloudflare Zero Trust).

---

## 3. FROGIO — Servicios (server01)

| Servicio | Puerto Interno | URL |
|----------|---------------|-----|
| **Landing** | 3025 | `frogio.cl` / `frogio.supertools.cl` |
| **Web-Admin** | 3111 | `frogio.cl/[tenant]` / `admin-frogio.supertools.cl` |
| **API Backend** | 3110 | `api-frogio.supertools.cl` |
| **PostgreSQL** | 5432 | (interno) |
| **Redis** | 6379 | (interno) |
| **MinIO** | 9100/9101 | `minio-frogio.supertools.cl` |
| **ntfy** | 8080 | `ntfy.supertools.cl` |
| **Uptime Kuma** | 3004 | `uptime.supertools.cl` |

### Credenciales BD (Santa Juana)

```
Database: frogio_santa_juana
User: frogio
Pass: FrogioDB2024
```

### MinIO Frogio

```
User: frogio_admin
Pass: frogio_secret_key_2024
```

### Cuentas de prueba (web-admin)

| Rol | Email | Password |
|-----|-------|----------|
| Ciudadano | ciudadano@test.cl | Ciudadano2024! |
| Inspector | inspector@test.cl | Inspector2024! |
| Admin | admin@test.cl | Admin2024! |

---

## 4. FROGIO — VPS Ñuñoa

| Servicio | Puerto | URL |
|----------|--------|-----|
| **API Backend** | 3101 | `api-nunoa.supertools.cl` (pendiente configurar) |
| **PostgreSQL** | 5432 | (interno) |
| **Redis** | 6379 | (interno) |

### Credenciales BD (Ñuñoa)

```
Database: frogio_nunoa
User: frogio
Pass: FrogioDB2024
```

### PM2

```bash
pm2 list          # Ver procesos
pm2 logs          # Ver logs
pm2 restart all   # Reiniciar
```

---

## 5. GITHUB

| Campo | Valor |
|-------|-------|
| **Repo** | https://github.com/Drozast/frogio |
| **Rama principal** | `main` |
| **Owner** | Drozast |

---

## 6. DOMINIOS

| Dominio | Propósito | Cloudflare Account |
|---------|-----------|-------------------|
| `frogio.cl` | Landing + Web-Admin | `bb907cb...` (separada) |
| `frogio.supertools.cl` | Landing (backup) | drozast |
| `admin-frogio.supertools.cl` | Web-Admin (backup) | drozast |
| `api-frogio.supertools.cl` | API Santa Juana | drozast |
| `api-nunoa.supertools.cl` | API Ñuñoa (pendiente) | drozast |
| `supertools.cl` | Plataforma principal | drozast |
| `rhom.cl` | RHOM | separada (Rhom2569@gmail.com) |

---

## 7. GOOGLE PLAY / APP STORE

| Plataforma | Costo | Cuenta |
|------------|-------|--------|
| Google Play | $25 USD (único) | rddigitalspa@gmail.com |
| Apple Developer | $99 USD/año | rddigitalspa@gmail.com |

### Bundle IDs

| Municipio | Android | iOS |
|-----------|---------|-----|
| Santa Juana | `com.frogio.santa_juana` | `com.frogio.santajuana` |
| Ñuñoa | `com.frogio.nunoa` | `com.frogio.nunoa` |

---

## 8. BUILD & DEPLOY

### Web-Admin (server01)

```bash
cd ~/frogio
git pull --ff-only origin main
docker compose build web-admin
docker compose up -d --force-recreate --no-deps web-admin
```

### Landing (server01)

```bash
# Sincronizar archivos modificados desde el repo
cp ~/frogio/frogioweb/nginx.conf ~/frogioweb/nginx.conf
cp ~/frogio/frogioweb/src/pages/*.tsx ~/frogioweb/src/pages/

# Rebuild
cd ~/frogioweb
docker compose build --no-cache
docker compose up -d
```

### API en VPS nuevo

```bash
# En el VPS:
/root/frogio-provision-vps.sh <tenant_id> <puerto_api> "Nombre Municipio"
```

### Flutter Build

```bash
# Santa Juana (default)
flutter build apk
flutter build ios

# Ñuñoa
flutter build apk --dart-define TENANT_ID=nunoa
flutter build ios --dart-define TENANT_ID=nunoa
```

---

## 9. ENLACES ÚTILES

- **Web-Admin Santa Juana:** https://frogio.cl/santa_juana/login
- **Web-Admin Ñuñoa:** https://frogio.cl/nunoa/login
- **API Santa Juana:** https://api-frogio.supertools.cl/health
- **Dashboard server01:** https://panel.supertools.cl
- **Uptime Kuma:** https://uptime.supertools.cl
- **Gitea:** https://git.supertools.cl
