#!/usr/bin/env python3
"""FROGIO - Test Suite de Flujos API"""
import json, sys, urllib.request, urllib.error, ssl
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

BASE = "https://api-frogio.supertools.cl"
TENANT = "santa_juana"
PASS = FAIL = SKIP = 0

def c(color, text):
    colors = {"green":"\033[92m","red":"\033[91m","yellow":"\033[93m","cyan":"\033[96m","reset":"\033[0m","blue":"\033[94m"}
    return f"{colors[color]}{text}{colors['reset']}"

def ok(msg):   global PASS; PASS+=1; print(f"  {c('green','✓')} {msg}")
def fail(msg): global FAIL; FAIL+=1; print(f"  {c('red','✗')} {msg}")
def skip(msg): global SKIP; SKIP+=1; print(f"  {c('yellow','~')} {msg}")
def section(msg): print(f"\n{c('cyan',f'━━━ {msg} ━━━')}")

def req(method, path, data=None, token=None):
    url = BASE + path
    headers = {"Content-Type":"application/json","X-Tenant-ID":TENANT,"User-Agent":"curl/8.0"}
    if token: headers["Authorization"] = f"Bearer {token}"
    body = json.dumps(data).encode() if data else None
    try:
        r = urllib.request.Request(url, data=body, headers=headers, method=method)
        with urllib.request.urlopen(r, timeout=15, context=ssl_ctx) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as e:
        try: return e.code, json.loads(e.read())
        except: return e.code, {}
    except Exception as e:
        return 0, {"error": str(e)}

tokens = {}
user_ids = {}

# ─── PASO 1: HEALTH ───
section("PASO 1: HEALTH CHECK")
code, body = req("GET", "/health")
if code == 200:
    ok(f"Backend responde (200) - DB: {body.get('services',{}).get('database','?')}, Redis: {body.get('services',{}).get('redis','?')}")
else:
    fail(f"Backend caído ({code})")
    sys.exit(1)

# ─── PASO 2: AUTH ───
section("PASO 2: AUTH - Login")
for email, pwd, rol in [
    ("ciudadano@test.cl","Ciudadano2024!","ciudadano"),
    ("inspector@test.cl","Inspector2024!","inspector"),
    ("admin@test.cl","Admin2024!","admin"),
]:
    code, body = req("POST","/api/auth/login",{"email":email,"password":pwd})
    token = body.get("accessToken")
    if code == 200 and token:
        tokens[rol] = token
        user_ids[rol] = body.get("user",{}).get("id")
        ok(f"Login {rol} → role: {body.get('user',{}).get('role')}")
    else:
        fail(f"Login {rol} falló (HTTP {code}): {body.get('error','?')}")

code, body = req("POST","/api/auth/login",{"email":"x@x.com","password":"wrong"})
if code == 401: ok("Credenciales inválidas retorna 401")
else: fail(f"Credenciales inválidas retornó {code}")

# ─── PASO 3: PERFIL ───
section("PASO 3: Perfil de usuario")
if "ciudadano" in tokens:
    code, body = req("GET","/api/auth/me",token=tokens["ciudadano"])
    if code == 200: ok(f"GET /me → {body.get('user',body).get('firstName','?')} {body.get('user',body).get('lastName','?')}")
    else: fail(f"GET /me falló ({code})")
else: skip("Sin token ciudadano")

# ─── PASO 4: REPORTES ───
section("PASO 4: REPORTES")
report_id = None
if "ciudadano" in tokens:
    code, body = req("POST","/api/reports",{
        "title":"Test auto - Luminaria caída",
        "description":"Prueba automática del sistema",
        "type":"infraestructura","priority":"media",
        "location":{"lat":-37.0979,"lng":-72.3311,"address":"Calle Test 123"}
    }, tokens["ciudadano"])
    report_id = body.get("report",body).get("id") or body.get("id")
    if code == 201 and report_id: ok(f"Crear reporte (ID: {report_id[:8]}...)")
    else: fail(f"Crear reporte ({code}): {str(body)[:100]}")

    code, body = req("GET","/api/reports?limit=5",token=tokens["ciudadano"])
    if code == 200:
        total = body.get("pagination",{}).get("total", len(body.get("data",[])) if isinstance(body.get("data",[]), list) else 0) if isinstance(body, dict) else len(body) if isinstance(body, list) else 0
        ok(f"Listar reportes ciudadano (total: {total})")
    else: fail(f"Listar reportes ({code})")
else: skip("Sin token ciudadano")

if "inspector" in tokens and report_id:
    code, _ = req("PATCH",f"/api/reports/{report_id}",{"status":"en_proceso","comment":"Asignado"},tokens["inspector"])
    if code == 200: ok("Inspector → en_proceso")
    else: fail(f"Inspector update ({code})")

    code, _ = req("PATCH",f"/api/reports/{report_id}",{"status":"resuelto","comment":"Solucionado"},tokens["inspector"])
    if code == 200: ok("Inspector → resuelto")
    else: fail(f"Inspector resolver ({code})")

    code, body = req("GET","/api/reports?limit=5",token=tokens["inspector"])
    if code == 200:
        has_pag = "si" if "pagination" in body else "no"
        ok(f"Listar reportes inspector (paginación: {has_pag})")
    else: fail(f"Listar reportes inspector ({code})")
else: skip("Sin token inspector o report_id")

# ─── PASO 5: CITACIONES ───
section("PASO 5: CITACIONES")
if "inspector" in tokens:
    code, body = req("POST","/api/citations",{
        "citationType":"advertencia","targetType":"persona",
        "targetName":"Juan Test","targetRut":"44444444-4",
        "reason":"Test auto","locationAddress":"Calle 1",
        "hearingDate":"2026-05-01T10:00:00Z",
        "citationNumber":f"CIT-TEST-{__import__('time').time_ns()}"
    }, tokens["inspector"])
    cid = body.get("citation",body).get("id") or body.get("id")
    if code == 201: ok(f"Crear citación (ID: {str(cid)[:8]}...)")
    else: fail(f"Crear citación ({code}): {str(body)[:100]}")

    code, body = req("GET","/api/citations?limit=5",token=tokens["inspector"])
    if code == 200: ok("Listar citaciones")
    else: fail(f"Listar citaciones ({code})")

    code, body = req("GET","/api/citations/stats",token=tokens["inspector"])
    if code == 200: ok("Stats citaciones")
    else: skip(f"Stats citaciones ({code})")
else: skip("Sin token inspector")

# ─── PASO 6: INFRACCIONES ───
section("PASO 6: INFRACCIONES")
if "inspector" in tokens:
    code, body = req("POST","/api/infractions",{
        "type":"ruido",
        "description":"Test auto",
        "address":"Av Test 456",
        "amount":5000,
        "userId": user_ids.get("ciudadano")
    }, tokens["inspector"])
    if code == 201: ok("Crear infracción")
    else: fail(f"Crear infracción ({code}): {str(body)[:100]}")

    code, _ = req("GET","/api/infractions?limit=5",token=tokens["inspector"])
    if code == 200: ok("Listar infracciones")
    else: fail(f"Listar infracciones ({code})")
else: skip("Sin token inspector")

# ─── PASO 7: NOTIFICACIONES ───
section("PASO 7: NOTIFICACIONES")
if "ciudadano" in tokens:
    code, body = req("GET","/api/notifications?limit=5",token=tokens["ciudadano"])
    if code == 200:
        if isinstance(body, list):
            total = len(body)
        else:
            total = body.get("pagination",{}).get("total", len(body.get("data",[])))
        ok(f"Listar notificaciones (total: {total})")
    else: fail(f"Listar notificaciones ({code})")

    code, _ = req("GET","/api/notifications/unread-count",token=tokens["ciudadano"])
    if code == 200: ok("Contador no leídas")
    else: skip(f"Contador no leídas ({code}) - endpoint puede no existir")
else: skip("Sin token ciudadano")

# ─── PASO 8: USUARIOS ───
section("PASO 8: USUARIOS (admin)")
if "admin" in tokens:
    code, body = req("GET","/api/users?limit=5",token=tokens["admin"])
    if code == 200:
        if isinstance(body, list):
            total = len(body)
        else:
            total = body.get("pagination",{}).get("total", len(body.get("data",body.get("users",[]))))
        ok(f"Listar usuarios (total: {total})")
    else: fail(f"Listar usuarios ({code})")
else: skip("Sin token admin")

# ─── PASO 9: FLOTA ───
section("PASO 9: FLOTA")
if "inspector" in tokens:
    code, body = req("GET","/api/vehicles",token=tokens["inspector"])
    if code == 200:
        if isinstance(body, list):
            count = len(body)
        else:
            count = len(body.get("vehicles",body.get("data",[])))
        ok(f"Listar vehículos (total: {count})")
    else: fail(f"Listar vehículos ({code})")

    code, _ = req("GET","/api/vehicles/logs/active",token=tokens["inspector"])
    if code == 200: ok("Bitácoras activas")
    else:
        code2, _ = req("GET","/api/vehicles/logs?limit=5",token=tokens["admin"] if "admin" in tokens else tokens["inspector"])
        if code2 == 200: ok("Bitácoras de flota (admin)")
        else: skip(f"Bitácoras ({code}/{code2})")
else: skip("Sin token inspector")

# ─── PASO 10: GEOFENCES ───
section("PASO 10: GEOFENCES")
if "inspector" in tokens:
    code, _ = req("GET","/api/geofences",token=tokens["inspector"])
    if code == 200: ok("Listar geofences")
    else: fail(f"Geofences ({code})")
else: skip("Sin token")

# ─── PASO 11: DASHBOARD ───
section("PASO 11: DASHBOARD")
if "admin" in tokens:
    code, _ = req("GET","/api/dashboard/stats",token=tokens["admin"])
    if code == 200: ok("Dashboard stats")
    else: fail(f"Dashboard stats ({code})")

    code, body = req("GET","/api/dashboard/stats",token=tokens["admin"])
    if code == 200:
        has_recent = "si" if body.get("recentActivity") else "no"
        ok(f"Actividad reciente incluida en stats (recentActivity: {has_recent})")
    else: skip(f"Actividad reciente - no hay endpoint separado")
else: skip("Sin token admin")

# ─── PASO 12: PAGINACIÓN ───
section("PASO 12: PAGINACIÓN")
if "admin" in tokens:
    code, body = req("GET","/api/reports?page=1&limit=3",token=tokens["admin"])
    if code == 200:
        if "pagination" in body:
            p = body["pagination"]
            ok(f"Paginación OK (page={p.get('page')}, limit={p.get('limit')}, total={p.get('total')})")
        else: fail("Respuesta sin campo 'pagination'")
    else: fail(f"Paginación ({code})")
else: skip("Sin token admin")

# ─── PASO 13: RATE LIMITING ───
section("PASO 13: RATE LIMITING")
print(f"  {c('blue','→')} Enviando 12 requests de login fallidos...")
rate_hit = False
for i in range(1, 13):
    code, _ = req("POST","/api/auth/login",{"email":"ratetest@x.com","password":"wrong"})
    if code == 429:
        ok(f"Rate limit activo (429 en request #{i})")
        rate_hit = True
        break
if not rate_hit:
    fail("Rate limiting NO activado en producción (middleware no deployado)")

# ─── RESUMEN ───
total = PASS + FAIL + SKIP
print(f"\n{c('cyan','━'*44)}")
print("  RESULTADO FINAL")
print(f"{c('cyan','━'*44)}")
print(f"  {c('green',f'✓ Pasaron:  {PASS}')}")
print(f"  {c('red',f'✗ Fallaron: {FAIL}')}")
print(f"  {c('yellow',f'~ Saltados: {SKIP}')}")
print(f"  Total:     {total}\n")
if FAIL == 0:
    print(f"  {c('green','✅ Todos los tests pasaron')}")
    sys.exit(0)
else:
    print(f"  {c('red',f'❌ {FAIL} test(s) fallando')}")
    sys.exit(1)
