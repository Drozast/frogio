# 🌐 Configuración de Cloudflare Tunnel para Frogio

Esta guía te ayudará a configurar Cloudflare Tunnel para exponer Frogio con subdominios personalizados de `drozast.xyz`.

---

## 🎯 Objetivo

Exponer los servicios de Frogio con subdominios seguros:
- **API Backend:** `https://api.frogio.drozast.xyz`
- **Web Admin:** `https://admin.frogio.drozast.xyz`

---

## 📋 Pre-requisitos

1. Cuenta de Cloudflare con el dominio `drozast.xyz` configurado
2. Acceso al servidor (192.168.31.115)
3. Docker instalado en el servidor
4. Servicios de Frogio corriendo

---

## 🚀 Pasos de Configuración

### 1. Crear Tunnel en Cloudflare Dashboard

**Opción A: Usando la Web UI**

1. Ve a [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navega a **Access > Tunnels**
3. Click en **Create a tunnel**
4. Nombre: `frogio-tunnel`
5. Click **Save tunnel**
6. **Copia el token** que aparece (necesitarás esto después)

**Opción B: Usando CLI (si tienes cloudflared instalado localmente)**

```bash
cloudflared tunnel create frogio-tunnel
```

Esto generará un archivo JSON con las credenciales.

### 2. Configurar DNS en Cloudflare

En el dashboard de Cloudflare, ve a **DNS** y agrega estos registros CNAME:

| Type | Name | Target | Proxy Status |
|------|------|--------|--------------|
| CNAME | api.frogio | frogio-tunnel.cfargotunnel.com | Proxied (naranja) |
| CNAME | admin.frogio | frogio-tunnel.cfargotunnel.com | Proxied (naranja) |

O usa el botón **Add a public hostname** en el tunnel dashboard.

### 3. Configurar el Tunnel en el Servidor

**Método Recomendado: Usando Docker Compose**

Agrega el servicio de Cloudflare al `docker-compose.full.yml`:

```yaml
# Agregar al archivo docker-compose.full.yml

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: frogio-cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token YOUR_TUNNEL_TOKEN_HERE
    networks:
      - frogio_network
    depends_on:
      - backend
      - web-admin
```

**Reemplaza `YOUR_TUNNEL_TOKEN_HERE`** con el token que copiaste en el paso 1.

### 4. Configurar Ingress Rules

Si prefieres usar un archivo de configuración en lugar del token:

1. Crea el archivo de credenciales:

```bash
# En el servidor
mkdir -p ~/frogio/cloudflare
```

2. Copia el archivo `cloudflare-config.yml` al servidor:

```bash
scp cloudflare-config.yml usuario@192.168.31.115:~/frogio/cloudflare/config.yml
```

3. Copia las credenciales del tunnel (archivo JSON que se generó al crear el tunnel):

```bash
scp ~/.cloudflared/UUID.json usuario@192.168.31.115:~/frogio/cloudflare/credentials.json
```

4. Actualiza docker-compose para usar el archivo de config:

```yaml
cloudflared:
  image: cloudflare/cloudflared:latest
  container_name: frogio-cloudflared
  restart: unless-stopped
  command: tunnel --config /etc/cloudflared/config.yml run
  volumes:
    - ./cloudflare:/etc/cloudflared
  networks:
    - frogio_network
  depends_on:
    - backend
    - web-admin
```

### 5. Levantar el Tunnel

```bash
cd ~/frogio
docker compose -f docker-compose.full.yml up -d cloudflared
```

### 6. Verificar que el Tunnel está activo

```bash
# Ver logs
docker logs frogio-cloudflared

# Deberías ver algo como:
# "Connection ... registered"
# "Started tunnel frogio-tunnel"
```

---

## 🧪 Testing

### 1. Verificar DNS

```bash
# Desde tu máquina local
dig api.frogio.drozast.xyz
dig admin.frogio.drozast.xyz
```

Deberían resolver a IPs de Cloudflare (104.x.x.x o 172.x.x.x).

### 2. Probar API

```bash
curl https://api.frogio.drozast.xyz/health
```

Respuesta esperada:
```json
{
  "status": "ok",
  "timestamp": "...",
  "services": {
    "database": "connected",
    "redis": "not configured"
  }
}
```

### 3. Probar Login

```bash
curl -X POST https://api.frogio.drozast.xyz/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: santa_juana" \
  -d '{
    "email": "admin@test.cl",
    "password": "Password123!"
  }'
```

### 4. Acceder al Web Admin

Abre en tu navegador:
```
https://admin.frogio.drozast.xyz
```

---

## 🔧 Actualizar URLs en las Aplicaciones

### Web Admin

Actualiza `.env.local`:
```env
NEXT_PUBLIC_API_URL=https://api.frogio.drozast.xyz
NEXT_PUBLIC_TENANT_ID=santa_juana
```

### Aplicación Móvil

Actualiza `apps/mobile/lib/core/config/api_config.dart`:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://api.frogio.drozast.xyz',
);
```

### Docker Compose

Actualiza `docker-compose.full.yml`:
```yaml
backend:
  environment:
    CORS_ORIGIN: "https://admin.frogio.drozast.xyz,*"

web-admin:
  environment:
    NEXT_PUBLIC_API_URL: https://api.frogio.drozast.xyz
```

---

## 🔒 Seguridad

### 1. Actualizar CORS

Una vez que uses dominios, actualiza CORS para ser más restrictivo:

```yaml
# docker-compose.full.yml
backend:
  environment:
    CORS_ORIGIN: "https://admin.frogio.drozast.xyz,https://api.frogio.drozast.xyz"
```

### 2. Configurar Certificados SSL

Cloudflare Tunnel maneja SSL automáticamente. El tráfico entre Cloudflare y tu servidor puede ser:

- **Flexible:** HTTP (menos seguro)
- **Full:** HTTPS con certificado auto-firmado
- **Full (strict):** HTTPS con certificado válido

Para mayor seguridad, configura **Full** en Cloudflare:
1. Dashboard de Cloudflare
2. SSL/TLS > Overview
3. Selecciona **Full**

### 3. Configurar Access Policies (Opcional)

Puedes restringir acceso al admin panel:

1. Cloudflare Dashboard > Access > Applications
2. Create Application
3. Añade `admin.frogio.drozast.xyz`
4. Configura reglas de acceso (email, IP, etc.)

---

## 🔍 Troubleshooting

### Tunnel no conecta

```bash
# Ver logs detallados
docker logs frogio-cloudflared -f

# Verificar que el token es correcto
# Verificar que la red está configurada correctamente
```

### Error 502 Bad Gateway

- Verifica que los servicios backend/web-admin estén corriendo
- Verifica que estén en la misma red Docker
- Revisa los logs del backend

### Error de CORS

- Actualiza CORS_ORIGIN en el backend
- Asegúrate de incluir el nuevo dominio
- Reinicia el backend después de cambios

### DNS no resuelve

- Espera unos minutos (propagación de DNS)
- Verifica que los registros CNAME estén en modo "Proxied" (naranja)
- Limpia caché de DNS: `ipconfig /flushdns` (Windows) o `sudo dscacheutil -flushcache` (Mac)

---

## 📊 Monitoreo

### Ver estadísticas del Tunnel

En Cloudflare Dashboard:
1. Zero Trust > Access > Tunnels
2. Click en `frogio-tunnel`
3. Ver métricas de tráfico y conexiones

### Alertas

Configura alertas en Cloudflare para:
- Tunnel desconectado
- Errores 5xx
- Tráfico anormal

---

## 🔄 Alternativa: Usar Cloudflare Quick Tunnels (Temporal)

Para testing rápido sin configuración:

```bash
# En el servidor
docker run cloudflare/cloudflared:latest tunnel --url http://localhost:3000

# Te dará una URL temporal como: https://random-name.trycloudflare.com
```

**Nota:** Esta URL es temporal y cambia cada vez que reinicias.

---

## 📝 Comandos Útiles

```bash
# Ver estado del tunnel
docker logs frogio-cloudflared --tail 50

# Reiniciar tunnel
docker compose -f docker-compose.full.yml restart cloudflared

# Ver conexiones activas
docker exec frogio-cloudflared cloudflared tunnel info

# Detener tunnel
docker compose -f docker-compose.full.yml stop cloudflared
```

---

## 🎯 Checklist Final

- [ ] Tunnel creado en Cloudflare Dashboard
- [ ] DNS CNAME records configurados
- [ ] Cloudflared container corriendo
- [ ] Tunnel conectado (ver logs)
- [ ] `https://api.frogio.drozast.xyz/health` responde
- [ ] `https://admin.frogio.drozast.xyz` carga
- [ ] Login funciona
- [ ] CORS actualizado
- [ ] URLs actualizadas en web-admin
- [ ] URLs actualizadas en mobile app
- [ ] SSL configurado (Full)
- [ ] Testing completo

---

## 🆘 Soporte

Si tienes problemas:
1. Revisa los logs del tunnel
2. Verifica la configuración de DNS
3. Consulta [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
4. Revisa el estado de Cloudflare: https://www.cloudflarestatus.com/
