# Instructivo de Conexión Remota al Servidor Drozast

## Para: shormero

Este documento explica cómo conectarte al servidor de desarrollo desde cualquier lugar usando Cloudflare Tunnel.

---

## Datos de Conexión

| Campo | Valor |
|-------|-------|
| **Usuario** | `shormero` |
| **Servidor** | `ssh.drozast.xyz` |
| **Contraseña** | *(solicitar a drozast)* |

---

## Paso 1: Instalar Cloudflared

### En Windows

1. Descarga el instalador desde: https://github.com/cloudflare/cloudflared/releases/latest
2. Busca el archivo `cloudflared-windows-amd64.msi`
3. Ejecuta el instalador y sigue las instrucciones
4. Reinicia la terminal (PowerShell o CMD) después de instalar

**Verificar instalación:**
```powershell
cloudflared --version
```

### En macOS

Abre Terminal y ejecuta:
```bash
brew install cloudflared
```

Si no tienes Homebrew, primero instálalo:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Verificar instalación:**
```bash
cloudflared --version
```

### En Linux (Ubuntu/Debian)

```bash
# Descargar e instalar
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb

# Verificar
cloudflared --version
```

---

## Paso 2: Conectarte al Servidor

### Comando de Conexión

```bash
ssh -o ProxyCommand="cloudflared access ssh --hostname ssh.drozast.xyz" shormero@ssh.drozast.xyz
```

Te pedirá la contraseña. Ingrésala y presiona Enter.

### En Windows (PowerShell)

```powershell
ssh -o ProxyCommand="cloudflared access ssh --hostname ssh.drozast.xyz" shormero@ssh.drozast.xyz
```

---

## Paso 3: Crear un Atajo (Opcional pero Recomendado)

Para no escribir el comando largo cada vez:

### En macOS/Linux

Edita el archivo `~/.ssh/config`:

```bash
nano ~/.ssh/config
```

Agrega estas líneas:

```
Host drozast
    HostName ssh.drozast.xyz
    User shormero
    ProxyCommand cloudflared access ssh --hostname %h
```

Guarda con `Ctrl+O`, Enter, y sal con `Ctrl+X`.

**Ahora puedes conectarte simplemente con:**
```bash
ssh drozast
```

### En Windows

Crea/edita el archivo `C:\Users\TU_USUARIO\.ssh\config`:

```
Host drozast
    HostName ssh.drozast.xyz
    User shormero
    ProxyCommand cloudflared access ssh --hostname %h
```

**Ahora puedes conectarte con:**
```powershell
ssh drozast
```

---

## Paso 4: Configurar VS Code (Opcional)

Si usas Visual Studio Code para editar código remotamente:

1. Instala la extensión **"Remote - SSH"**
2. Presiona `F1` → escribe "Remote-SSH: Connect to Host"
3. Selecciona `drozast` (si configuraste el atajo)
4. Ingresa tu contraseña cuando la pida

---

## Comandos Útiles una vez Conectado

```bash
# Ver estado de los servicios
sudo systemctl status docker
docker ps

# Ver logs del backend
docker logs frogio-backend -f --tail 100

# Ir al directorio del proyecto
cd /home/drozast/frogio

# Ver estado de git
git status
```

---

## Solución de Problemas

### "cloudflared: command not found"
- Reinicia tu terminal después de instalar
- En Windows, asegúrate de que está en el PATH

### "Connection refused" o "No route to host"
- NO uses `ssh shormero@ssh.drozast.xyz` directamente
- SIEMPRE usa el ProxyCommand con cloudflared

### "Permission denied"
- Verifica que estás usando el usuario correcto (`shormero`)
- Verifica que la contraseña sea correcta

### La conexión tarda mucho
- Es normal que tarde 2-5 segundos la primera vez
- Si tarda más de 30 segundos, verifica tu conexión a internet

---

## Contacto

Si tienes problemas, contacta a **drozast** con:
- Captura de pantalla del error
- Sistema operativo que usas
- Comando exacto que ejecutaste

---

*Documento generado el 26 de enero de 2026*
