# 📱 Frogio Mobile - Configuración de Producción

## 🌐 Servidor de Producción

La aplicación móvil está configurada para conectarse al servidor de producción:

- **API Backend:** `http://192.168.31.115:3000`
- **Tenant ID:** `santa_juana`
- **Ntfy (Notificaciones):** `http://192.168.31.115:8089`

## 🔧 Configuración

La configuración se encuentra en:
```
lib/core/config/api_config.dart
```

### URLs por Defecto

```dart
baseUrl: 'http://192.168.31.115:3000'
tenantId: 'santa_juana'
ntfyUrl: 'http://192.168.31.115:8089'
```

## 🏗️ Compilar para Producción

### Android

```bash
# Debug APK (para pruebas)
flutter build apk --debug

# Release APK (producción)
flutter build apk --release

# App Bundle (para Google Play)
flutter build appbundle --release
```

### iOS

```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

## 🔐 Variables de Entorno (Opcional)

Si quieres usar diferentes URLs sin modificar el código, puedes usar variables de entorno:

```bash
# Compilar con URL personalizada
flutter build apk --release \
  --dart-define=API_URL=http://tu-servidor.com:3000 \
  --dart-define=TENANT_ID=santa_juana
```

## 🧪 Testing Local

Para probar localmente antes de compilar:

```bash
# Modo debug con hot reload
flutter run

# Asegúrate de estar en la misma red que el servidor (192.168.31.x)
```

## 📝 Notas Importantes

1. **Red Local**: El servidor `192.168.31.115` solo es accesible desde la red local
2. **HTTP vs HTTPS**: Actualmente usa HTTP. Para producción real, considera configurar HTTPS
3. **Permisos**: Asegúrate de que la app tiene permisos de Internet en:
   - `android/app/src/main/AndroidManifest.xml`
   - `ios/Runner/Info.plist`

## 🚀 Despliegue

### Para Testing Interno (Android)

1. Compilar APK debug:
   ```bash
   flutter build apk --debug
   ```

2. El APK estará en:
   ```
   build/app/outputs/flutter-apk/app-debug.apk
   ```

3. Distribuir via:
   - USB/ADB: `flutter install`
   - Email/Drive: Enviar el APK
   - Firebase App Distribution
   - TestFlight (iOS)

### Para Producción (Android)

1. Firmar la app (necesitas keystore)
2. Compilar release APK:
   ```bash
   flutter build apk --release
   ```
3. O compilar App Bundle:
   ```bash
   flutter build appbundle --release
   ```

## 🔍 Troubleshooting

### No conecta al servidor

1. Verificar que estás en la misma red (192.168.31.x)
2. Ping al servidor: `ping 192.168.31.115`
3. Verificar que el backend está corriendo:
   ```bash
   curl http://192.168.31.115:3000/health
   ```

### Errores de certificado (iOS)

Si usas HTTP en iOS, necesitas configurar App Transport Security:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

### Errores de red en Android

Verificar permiso en `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## 📊 Endpoints Disponibles

- `GET /health` - Health check del backend
- `POST /api/auth/login` - Login de usuarios
- `GET /api/infractions` - Listar infracciones
- `POST /api/infractions` - Crear infracción (inspector)
- `GET /api/reports` - Listar reportes
- `POST /api/reports` - Crear reporte (ciudadano)

## 🎯 Usuarios de Prueba

```
Admin:
- Email: admin@test.cl
- Password: Password123!

Inspector:
- Email: inspector@test.cl
- Password: Password123!

Ciudadano:
- Email: ciudadano@test.cl
- Password: Password123!
```
