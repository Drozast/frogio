# FROGIOWEB - Landing Page

## Descripcion
Landing page para la aplicación móvil Frogio: Seguridad Municipal.

## URLs de Produccion
- **Landing**: https://frogio.cl
- **Privacidad**: https://frogio.cl/privacidad
- **Eliminacion de cuenta**: https://frogio.cl/eliminacion

## Despliegue

### Servidor
```bash
IP: 192.168.31.145
Usuario: drozast
Password: 123
Ruta: ~/frogioweb
```

### Comandos de Deploy
```bash
# Conectar al servidor
ssh drozast@192.168.31.145

# Ir al proyecto
cd ~/frogioweb

# Rebuild y restart
docker compose build --no-cache && docker compose up -d

# Ver logs
docker logs frogioweb -f
```

### Contenedores
| Container | Puerto | Descripcion |
|-----------|--------|-------------|
| frogioweb | 3025 | Nginx con landing page |
| cloudflared-frogio | - (host) | Tunnel a frogio.cl |

### Cloudflare (cuenta separada)
```
Email: frogiodevweb@gmail.com
Zone ID: 19db75eadc867914ad3f06d5a2036d7b
Account ID: bb907cb77668153e43379d32aa848212
Tunnel ID: b37abf48-fd37-475e-973f-62e4c8f8ca23
```

### Recrear tunnel si se cae
```bash
docker run -d --name cloudflared-frogio --network host --restart unless-stopped \
  cloudflare/cloudflared:latest tunnel --no-autoupdate run \
  --token eyJhIjoiYmI5MDdjYjc3NjY4MTUzZTQzMzc5ZDMyYWE4NDgyMTIiLCJ0IjoiYjM3YWJmNDgtZmQzNy00NzVlLTk3M2YtNjJlNGM4ZjhjYTIzIiwicyI6InBlRi9TTEFZb2lHNHl6S3h2VVB2emtER28yalN4K2tTcTlEekFrZXQ5M1k9In0=
```

## Stack Tecnologico
- React 18 + Vite + TypeScript
- Tailwind CSS + shadcn/ui
- Docker + Nginx
- Cloudflare Tunnel

## Paginas
- `/` - Landing principal
- `/privacidad` - Politica de privacidad
- `/eliminacion` - Eliminacion de cuenta
- `/privacy-policy` - Alias de privacidad
- `/account-deletion` - Alias de eliminacion
