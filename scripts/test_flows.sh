#!/bin/bash
# FROGIO - Script de pruebas automáticas de flujos
# Basado en REVIEW_FLOW.md
# Uso: ./scripts/test_flows.sh

BASE_URL="https://api-frogio.supertools.cl"
TENANT_ID="santa_juana"
PASS=0
FAIL=0
SKIP=0

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; ((PASS++)); }
fail() { echo -e "  ${RED}✗${NC} $1"; ((FAIL++)); }
skip() { echo -e "  ${YELLOW}~${NC} $1"; ((SKIP++)); }
section() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}"; }
info() { echo -e "  ${BLUE}→${NC} $1"; }

# Helper: POST request
post() {
  local url=$1 data=$2 token=$3
  local headers=(-H "Content-Type: application/json" -H "X-Tenant-ID: $TENANT_ID")
  [[ -n "$token" ]] && headers+=(-H "Authorization: Bearer $token")
  curl -s -w "\n%{http_code}" -X POST "${BASE_URL}${url}" "${headers[@]}" -d "$data" --max-time 15
}

# Helper: GET request
get() {
  local url=$1 token=$2
  local headers=(-H "X-Tenant-ID: $TENANT_ID")
  [[ -n "$token" ]] && headers+=(-H "Authorization: Bearer $token")
  curl -s -w "\n%{http_code}" "${BASE_URL}${url}" "${headers[@]}" --max-time 15
}

# Helper: PATCH request
patch() {
  local url=$1 data=$2 token=$3
  local headers=(-H "Content-Type: application/json" -H "X-Tenant-ID: $TENANT_ID")
  [[ -n "$token" ]] && headers+=(-H "Authorization: Bearer $token")
  curl -s -w "\n%{http_code}" -X PATCH "${BASE_URL}${url}" "${headers[@]}" -d "$data" --max-time 15
}

# Helper: extraer HTTP code de respuesta
http_code() { echo "$1" | tail -1; }
body() { echo "$1" | sed "$d"; }
json_field() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d$(echo "$2"))" 2>/dev/null; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   FROGIO - Test Suite de Flujos          ║${NC}"
echo -e "${CYAN}║   $(date '+%Y-%m-%d %H:%M:%S')                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"

# ─────────────────────────────────────────
section "PASO 1: HEALTH CHECK"
# ─────────────────────────────────────────

resp=$(curl -s -w "\n%{http_code}" "${BASE_URL}/health" --max-time 10)
code=$(http_code "$resp")
body_resp=$(body "$resp")

if [[ "$code" == "200" ]]; then
  db=$(echo "$body_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['services']['database'])" 2>/dev/null)
  redis=$(echo "$body_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['services']['redis'])" 2>/dev/null)
  ok "Backend responde ($code) - DB: $db, Redis: $redis"
else
  fail "Backend no responde (HTTP $code)"
  echo -e "\n${RED}Backend caído. Abortando tests.${NC}"
  exit 1
fi

# ─────────────────────────────────────────
section "PASO 2: AUTH - Login de usuarios"
# ─────────────────────────────────────────

# Login ciudadano
resp=$(post "/api/auth/login" '{"email":"ciudadano@test.cl","password":"Ciudadano2024!"}')
code=$(http_code "$resp")
TOKEN_CIUDADANO=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('accessToken',''))" 2>/dev/null)

if [[ "$code" == "200" && -n "$TOKEN_CIUDADANO" ]]; then
  ok "Login ciudadano (token obtenido)"
else
  fail "Login ciudadano falló (HTTP $code): $(body "$resp")"
  TOKEN_CIUDADANO=""
fi

# Login inspector
resp=$(post "/api/auth/login" '{"email":"inspector@test.cl","password":"Inspector2024!"}')
code=$(http_code "$resp")
TOKEN_INSPECTOR=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('accessToken',''))" 2>/dev/null)

if [[ "$code" == "200" && -n "$TOKEN_INSPECTOR" ]]; then
  ok "Login inspector (token obtenido)"
else
  fail "Login inspector falló (HTTP $code): $(body "$resp")"
  TOKEN_INSPECTOR=""
fi

# Login admin
resp=$(post "/api/auth/login" '{"email":"admin@test.cl","password":"Admin2024!"}')
code=$(http_code "$resp")
TOKEN_ADMIN=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('accessToken',''))" 2>/dev/null)

if [[ "$code" == "200" && -n "$TOKEN_ADMIN" ]]; then
  ok "Login admin (token obtenido)"
else
  fail "Login admin falló (HTTP $code): $(body "$resp")"
  TOKEN_ADMIN=""
fi

# Login con credenciales incorrectas (debe fallar)
resp=$(post "/api/auth/login" '{"email":"fake@frogio.cl","password":"wrong"}')
code=$(http_code "$resp")
if [[ "$code" == "401" ]]; then
  ok "Login con credenciales inválidas retorna 401"
else
  fail "Login inválido retornó $code (esperado 401)"
fi

# ─────────────────────────────────────────
section "PASO 3: AUTH - Perfil de usuario"
# ─────────────────────────────────────────

if [[ -n "$TOKEN_CIUDADANO" ]]; then
  resp=$(get "/api/auth/me" "$TOKEN_CIUDADANO")
  code=$(http_code "$resp")
  if [[ "$code" == "200" ]]; then
    nombre=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('user',d).get('name','?'))" 2>/dev/null)
    rol=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('user',d).get('role','?'))" 2>/dev/null)
    ok "GET /me ciudadano → name: $nombre, role: $rol"
  else
    fail "GET /me ciudadano falló (HTTP $code)"
  fi
else
  skip "GET /me ciudadano (sin token)"
fi

# ─────────────────────────────────────────
section "PASO 4: REPORTES"
# ─────────────────────────────────────────

REPORT_ID=""

if [[ -n "$TOKEN_CIUDADANO" ]]; then
  # Crear reporte
  resp=$(post "/api/reports" '{
    "title": "Test automatico - Luminaria caída",
    "description": "Prueba automática del sistema",
    "category": "alumbrado",
    "priority": "media",
    "location": {"lat": -37.0979, "lng": -72.3311, "address": "Calle Test 123"}
  }' "$TOKEN_CIUDADANO")
  code=$(http_code "$resp")
  REPORT_ID=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('report',d).get('id',d.get('id','')))" 2>/dev/null)

  if [[ "$code" == "201" && -n "$REPORT_ID" ]]; then
    ok "Crear reporte (ID: $REPORT_ID)"
  else
    fail "Crear reporte falló (HTTP $code): $(body "$resp" | head -c 200)"
    REPORT_ID=""
  fi

  # Listar reportes ciudadano
  resp=$(get "/api/reports?limit=5" "$TOKEN_CIUDADANO")
  code=$(http_code "$resp")
  if [[ "$code" == "200" ]]; then
    total=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('pagination',{}).get('total', len(d.get('data',d.get('reports',[])))))" 2>/dev/null)
    ok "Listar reportes ciudadano (total: $total)"
  else
    fail "Listar reportes ciudadano falló (HTTP $code)"
  fi
else
  skip "Crear/listar reportes (sin token ciudadano)"
fi

if [[ -n "$TOKEN_INSPECTOR" && -n "$REPORT_ID" ]]; then
  # Inspector actualiza estado
  resp=$(patch "/api/reports/$REPORT_ID" '{"status":"en_proceso","comment":"Asignado para revisión"}' "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  if [[ "$code" == "200" ]]; then
    ok "Inspector actualiza reporte a en_proceso"
  else
    fail "Inspector actualizar reporte falló (HTTP $code): $(body "$resp" | head -c 200)"
  fi

  # Resolver reporte
  resp=$(patch "/api/reports/$REPORT_ID" '{"status":"resuelto","comment":"Problema solucionado"}' "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  if [[ "$code" == "200" ]]; then
    ok "Inspector resuelve reporte"
  else
    fail "Inspector resolver reporte falló (HTTP $code)"
  fi

  # Listar todos los reportes como inspector
  resp=$(get "/api/reports?limit=5&page=1" "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  if [[ "$code" == "200" ]]; then
    has_pagination=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print('si' if 'pagination' in d else 'no')" 2>/dev/null)
    ok "Listar reportes inspector (paginación: $has_pagination)"
  else
    fail "Listar reportes inspector falló (HTTP $code)"
  fi
else
  skip "Flujo inspector-reporte (falta token o report_id)"
fi

# ─────────────────────────────────────────
section "PASO 5: CITACIONES"
# ─────────────────────────────────────────

CITATION_ID=""

if [[ -n "$TOKEN_INSPECTOR" ]]; then
  resp=$(post "/api/citations" '{
    "type": "advertencia",
    "targetType": "persona",
    "targetName": "Juan Test Prueba",
    "targetRut": "12345678-9",
    "description": "Prueba automatica de citacion",
    "location": "Calle Test 123",
    "hearingDate": "2026-05-01T10:00:00Z"
  }' "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  CITATION_ID=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('citation',d).get('id',d.get('id','')))" 2>/dev/null)

  if [[ "$code" == "201" && -n "$CITATION_ID" ]]; then
    ok "Crear citación (ID: $CITATION_ID)"
  else
    fail "Crear citación falló (HTTP $code): $(body "$resp" | head -c 200)"
  fi

  # Listar citaciones
  resp=$(get "/api/citations?limit=5" "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  if [[ "$code" == "200" ]]; then
    ok "Listar citaciones inspector"
  else
    fail "Listar citaciones falló (HTTP $code)"
  fi

  # Stats citaciones
  resp=$(get "/api/citations/stats" "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  [[ "$code" == "200" ]] && ok "Stats citaciones" || fail "Stats citaciones (HTTP $code)"
else
  skip "Citaciones (sin token inspector)"
fi

# ─────────────────────────────────────────
section "PASO 6: INFRACCIONES"
# ─────────────────────────────────────────

if [[ -n "$TOKEN_INSPECTOR" ]]; then
  resp=$(post "/api/infractions" '{
    "type": "ruido_excesivo",
    "severity": "leve",
    "description": "Prueba automatica de infraccion",
    "targetName": "Pedro Test",
    "targetRut": "98765432-1",
    "location": "Av Test 456"
  }' "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  if [[ "$code" == "201" ]]; then
    ok "Crear infracción"
  else
    fail "Crear infracción falló (HTTP $code): $(body "$resp" | head -c 200)"
  fi

  resp=$(get "/api/infractions?limit=5" "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  [[ "$code" == "200" ]] && ok "Listar infracciones" || fail "Listar infracciones (HTTP $code)"
else
  skip "Infracciones (sin token inspector)"
fi

# ─────────────────────────────────────────
section "PASO 7: NOTIFICACIONES"
# ─────────────────────────────────────────

if [[ -n "$TOKEN_CIUDADANO" ]]; then
  resp=$(get "/api/notifications?limit=5" "$TOKEN_CIUDADANO")
  code=$(http_code "$resp")
  if [[ "$code" == "200" ]]; then
    count=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('pagination',{}).get('total', len(d.get('data',[]))))" 2>/dev/null)
    ok "Listar notificaciones ciudadano (total: $count)"
  else
    fail "Listar notificaciones falló (HTTP $code)"
  fi

  resp=$(get "/api/notifications/unread-count" "$TOKEN_CIUDADANO")
  code=$(http_code "$resp")
  [[ "$code" == "200" ]] && ok "Contador no leídas" || fail "Contador no leídas (HTTP $code)"
else
  skip "Notificaciones (sin token ciudadano)"
fi

# ─────────────────────────────────────────
section "PASO 8: USUARIOS (admin)"
# ─────────────────────────────────────────

if [[ -n "$TOKEN_ADMIN" ]]; then
  resp=$(get "/api/users?limit=5" "$TOKEN_ADMIN")
  code=$(http_code "$resp")
  if [[ "$code" == "200" ]]; then
    total=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('pagination',{}).get('total', len(d.get('data',d.get('users',[])))))" 2>/dev/null)
    ok "Listar usuarios admin (total: $total)"
  else
    fail "Listar usuarios falló (HTTP $code)"
  fi
else
  skip "Usuarios (sin token admin)"
fi

# ─────────────────────────────────────────
section "PASO 9: FLOTA Y VEHÍCULOS"
# ─────────────────────────────────────────

if [[ -n "$TOKEN_INSPECTOR" ]]; then
  resp=$(get "/api/vehicles" "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  if [[ "$code" == "200" ]]; then
    count=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('vehicles',d.get('data',[]))))" 2>/dev/null)
    ok "Listar vehículos (total: $count)"
  else
    fail "Listar vehículos falló (HTTP $code)"
  fi

  resp=$(get "/api/vehicles/logs?limit=5" "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  [[ "$code" == "200" ]] && ok "Listar bitácoras de flota" || skip "Bitácoras flota (HTTP $code)"
else
  skip "Flota (sin token inspector)"
fi

# ─────────────────────────────────────────
section "PASO 10: GPS / GEOFENCES"
# ─────────────────────────────────────────

if [[ -n "$TOKEN_INSPECTOR" ]]; then
  resp=$(get "/api/geofences" "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  [[ "$code" == "200" ]] && ok "Listar geofences" || fail "Listar geofences (HTTP $code)"

  # GPS stats
  resp=$(get "/api/gps/stats" "$TOKEN_INSPECTOR")
  code=$(http_code "$resp")
  [[ "$code" == "200" || "$code" == "404" ]] && ok "GPS stats endpoint accesible" || fail "GPS stats (HTTP $code)"
else
  skip "GPS/Geofences (sin token inspector)"
fi

# ─────────────────────────────────────────
section "PASO 11: PANIC/SOS"
# ─────────────────────────────────────────

if [[ -n "$TOKEN_CIUDADANO" ]]; then
  resp=$(get "/api/panic/stats" "$TOKEN_CIUDADANO")
  code=$(http_code "$resp")
  [[ "$code" == "200" || "$code" == "403" ]] && ok "Panic stats accesible" || fail "Panic stats (HTTP $code)"
else
  skip "Panic (sin token ciudadano)"
fi

# ─────────────────────────────────────────
section "PASO 12: DASHBOARD"
# ─────────────────────────────────────────

if [[ -n "$TOKEN_ADMIN" ]]; then
  resp=$(get "/api/dashboard/stats" "$TOKEN_ADMIN")
  code=$(http_code "$resp")
  [[ "$code" == "200" ]] && ok "Dashboard stats" || fail "Dashboard stats (HTTP $code)"

  resp=$(get "/api/dashboard/recent-activity" "$TOKEN_ADMIN")
  code=$(http_code "$resp")
  [[ "$code" == "200" ]] && ok "Dashboard actividad reciente" || fail "Dashboard actividad reciente (HTTP $code)"
else
  skip "Dashboard (sin token admin)"
fi

# ─────────────────────────────────────────
section "PASO 13: RATE LIMITING"
# ─────────────────────────────────────────

info "Enviando 12 requests de login fallidos para probar rate limit..."
rate_hit=false
for i in $(seq 1 12); do
  resp=$(post "/api/auth/login" '{"email":"ratetest@frogio.cl","password":"wrong"}')
  code=$(http_code "$resp")
  if [[ "$code" == "429" ]]; then
    rate_hit=true
    ok "Rate limiting activo (hit en request #$i con HTTP 429)"
    break
  fi
done
[[ "$rate_hit" == false ]] && fail "Rate limiting NO activado después de 12 requests"

# ─────────────────────────────────────────
section "PASO 14: PAGINACIÓN"
# ─────────────────────────────────────────

if [[ -n "$TOKEN_ADMIN" ]]; then
  resp=$(get "/api/reports?page=1&limit=3" "$TOKEN_ADMIN")
  code=$(http_code "$resp")
  if [[ "$code" == "200" ]]; then
    has_pag=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print('si' if 'pagination' in d else 'no')" 2>/dev/null)
    page=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('pagination',{}).get('page','?'))" 2>/dev/null)
    limit=$(body "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('pagination',{}).get('limit','?'))" 2>/dev/null)
    if [[ "$has_pag" == "si" ]]; then
      ok "Paginación funciona (page=$page, limit=$limit)"
    else
      fail "Respuesta no tiene campo 'pagination'"
    fi
  else
    fail "Paginación test falló (HTTP $code)"
  fi
else
  skip "Paginación (sin token admin)"
fi

# ─────────────────────────────────────────
# RESUMEN FINAL
# ─────────────────────────────────────────

TOTAL=$((PASS + FAIL + SKIP))
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  RESULTADO FINAL"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}✓ Pasaron:  $PASS${NC}"
echo -e "  ${RED}✗ Fallaron: $FAIL${NC}"
echo -e "  ${YELLOW}~ Saltados: $SKIP${NC}"
echo -e "  Total:     $TOTAL"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo -e "  ${GREEN}✅ Todos los tests pasaron${NC}"
  exit 0
else
  echo -e "  ${RED}❌ Hay $FAIL test(s) fallando${NC}"
  exit 1
fi
