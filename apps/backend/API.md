# FROGIO Backend API Documentation

## Base URL
- Development: `http://localhost:3000`
- Production: `https://api.frogio.cl`

## Authentication

All endpoints (except auth endpoints) require authentication via JWT Bearer token.

**Headers Required:**
```
Authorization: Bearer {access_token}
X-Tenant-ID: {municipality_id}  // e.g., "santa_juana"
```

---

## 📋 Endpoints

### 🔐 Authentication (`/api/auth`)

#### POST `/api/auth/register`
Register a new user.

**Headers:**
- `X-Tenant-ID: santa_juana`

**Body:**
```json
{
  "email": "usuario@example.com",
  "password": "password123",
  "rut": "12345678-9",
  "firstName": "Juan",
  "lastName": "Pérez",
  "phone": "+56912345678",
  "role": "citizen"  // Optional: citizen | inspector | admin
}
```

**Response (201):**
```json
{
  "user": {
    "id": "uuid",
    "email": "usuario@example.com",
    "rut": "12345678-9",
    "firstName": "Juan",
    "lastName": "Pérez",
    "phone": "+56912345678",
    "role": "citizen",
    "isActive": true
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

#### POST `/api/auth/login`
Login with email and password.

**Headers:**
- `X-Tenant-ID: santa_juana`

**Body:**
```json
{
  "email": "usuario@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "user": { ... },
  "accessToken": "...",
  "refreshToken": "..."
}
```

---

#### POST `/api/auth/refresh`
Refresh access token using refresh token.

**Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "accessToken": "new_access_token",
  "refreshToken": "new_refresh_token"
}
```

---

#### POST `/api/auth/logout`
Logout (blacklists refresh token).

**Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "message": "Sesión cerrada exitosamente"
}
```

---

#### GET `/api/auth/me`
Get current authenticated user info.

**Headers:**
- `Authorization: Bearer {token}`

**Response (200):**
```json
{
  "user": {
    "userId": "uuid",
    "email": "usuario@example.com",
    "role": "citizen",
    "tenantId": "santa_juana"
  }
}
```

---

### 📢 Reports (`/api/reports`)

#### POST `/api/reports`
Create a new report (all authenticated users).

**Headers:**
- `Authorization: Bearer {token}`

**Body:**
```json
{
  "type": "denuncia",  // denuncia | sugerencia | emergencia | infraestructura | otro
  "title": "Bache en calle principal",
  "description": "Hay un bache grande en la calle O'Higgins",
  "address": "Calle O'Higgins 123",
  "latitude": -37.1234,
  "longitude": -72.5678,
  "priority": "media"  // Optional: baja | media | alta | urgente
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "type": "denuncia",
  "title": "Bache en calle principal",
  "description": "Hay un bache grande...",
  "address": "Calle O'Higgins 123",
  "latitude": -37.1234,
  "longitude": -72.5678,
  "priority": "media",
  "status": "pendiente",
  "created_at": "2024-12-14T10:30:00Z",
  "updated_at": "2024-12-14T10:30:00Z"
}
```

---

#### GET `/api/reports`
List reports (citizens see only their own, inspectors/admins see all).

**Query Parameters:**
- `status`: Filter by status (pendiente | en_proceso | resuelto | rechazado)
- `type`: Filter by type (denuncia | sugerencia | emergencia | infraestructura | otro)

**Response (200):**
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "first_name": "Juan",
    "last_name": "Pérez",
    "email": "juan@example.com",
    "type": "denuncia",
    "title": "Bache en calle principal",
    "status": "pendiente",
    "priority": "media",
    "created_at": "2024-12-14T10:30:00Z",
    ...
  }
]
```

---

#### GET `/api/reports/:id`
Get report details by ID.

**Response (200):**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "first_name": "Juan",
  "last_name": "Pérez",
  "email": "juan@example.com",
  "phone": "+56912345678",
  "type": "denuncia",
  "title": "Bache en calle principal",
  "description": "...",
  "status": "pendiente",
  ...
}
```

---

#### PATCH `/api/reports/:id`
Update report (inspectors/admins only).

**Body:**
```json
{
  "status": "en_proceso",
  "priority": "alta",
  "assignedTo": "inspector_user_id",
  "resolution": "Se asignó cuadrilla para reparación"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "status": "en_proceso",
  "priority": "alta",
  ...
}
```

---

#### DELETE `/api/reports/:id`
Delete report (admins only).

**Response (200):**
```json
{
  "message": "Reporte eliminado exitosamente"
}
```

---

### 🚨 Infractions (`/api/infractions`)

#### POST `/api/infractions`
Create infraction/fine (inspectors/admins only).

**Body:**
```json
{
  "userId": "uuid",
  "type": "trafico",  // trafico | ruido | basura | construccion | otro
  "description": "Exceso de velocidad en zona escolar",
  "address": "Calle Escuela 456",
  "latitude": -37.1234,
  "longitude": -72.5678,
  "amount": 50000,  // Amount in CLP
  "vehiclePlate": "AA-BB-12"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "type": "trafico",
  "description": "Exceso de velocidad...",
  "amount": 50000,
  "vehicle_plate": "AA-BB-12",
  "status": "pendiente",
  "issued_by": "inspector_user_id",
  "created_at": "2024-12-14T11:00:00Z",
  ...
}
```

---

#### GET `/api/infractions`
List infractions (citizens see only their own).

**Query Parameters:**
- `status`: Filter by status (pendiente | pagada | anulada)

**Response (200):**
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "user_first_name": "Juan",
    "user_last_name": "Pérez",
    "user_email": "juan@example.com",
    "issuer_first_name": "Inspector",
    "issuer_last_name": "González",
    "type": "trafico",
    "amount": 50000,
    "status": "pendiente",
    "created_at": "2024-12-14T11:00:00Z",
    ...
  }
]
```

---

#### GET `/api/infractions/stats`
Get infraction statistics.

**Response (200):**
```json
{
  "total": 15,
  "pendientes": 8,
  "pagadas": 5,
  "anuladas": 2,
  "monto_pendiente": 400000,
  "monto_pagado": 250000
}
```

---

#### GET `/api/infractions/:id`
Get infraction details.

**Response (200):**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "user_first_name": "Juan",
  "user_last_name": "Pérez",
  "user_email": "juan@example.com",
  "user_phone": "+56912345678",
  "user_rut": "12345678-9",
  "type": "trafico",
  "description": "...",
  "amount": 50000,
  "status": "pendiente",
  ...
}
```

---

#### PATCH `/api/infractions/:id`
Update infraction (inspectors/admins only).

**Body:**
```json
{
  "status": "pagada",
  "paymentMethod": "transferencia",  // efectivo | transferencia | tarjeta | webpay
  "paymentReference": "TRX-123456",
  "notes": "Pago verificado"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "status": "pagada",
  "payment_method": "transferencia",
  "payment_reference": "TRX-123456",
  "paid_at": "2024-12-14T12:00:00Z",
  ...
}
```

---

#### DELETE `/api/infractions/:id`
Delete infraction (admins only).

**Response (200):**
```json
{
  "message": "Infracción eliminada exitosamente"
}
```

---

## 🛡️ Role-Based Access Control (RBAC)

### Roles:
- **citizen**: Normal users, can create reports and view their own data
- **inspector**: Can create/update reports and infractions, view all data
- **admin**: Full access, can delete records

### Permission Matrix:

| Endpoint | Citizen | Inspector | Admin |
|----------|---------|-----------|-------|
| POST /reports | ✅ | ✅ | ✅ |
| GET /reports | Own only | All | All |
| PATCH /reports | ❌ | ✅ | ✅ |
| DELETE /reports | ❌ | ❌ | ✅ |
| POST /infractions | ❌ | ✅ | ✅ |
| GET /infractions | Own only | All | All |
| PATCH /infractions | ❌ | ✅ | ✅ |
| DELETE /infractions | ❌ | ❌ | ✅ |

---

## ❌ Error Responses

All error responses follow this format:

```json
{
  "error": "Error message here"
}
```

**Common HTTP Status Codes:**
- `400 Bad Request`: Invalid input data
- `401 Unauthorized`: Missing or invalid token
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

---

## 🌐 Multi-Tenancy

FROGIO uses PostgreSQL schemas for multi-tenancy. Each municipality has its own schema.

**Municipality IDs:**
- `santa_juana` - Santa Juana (pilot)
- More municipalities will be added as they subscribe

Always include the `X-Tenant-ID` header when registering or logging in.

---

## 🔒 Security Features

- **JWT Authentication**: 15-minute access tokens, 7-day refresh tokens
- **Password Hashing**: bcrypt with salt rounds = 12
- **RUT Validation**: Chilean RUT format validation with verification digit
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **CORS**: Configured for web admin and mobile app origins
- **Helmet.js**: Security headers protection
- **Token Blacklisting**: Logout invalidates refresh tokens via Redis

---

## 📊 Health Check

#### GET `/health`
Check API and services status.

**Response (200):**
```json
{
  "status": "ok",
  "timestamp": "2024-12-14T10:00:00Z",
  "services": {
    "database": "connected",
    "redis": "connected"
  }
}
```

---

## 🚀 Next Steps (To Be Implemented)

- Court Citations module
- Medical Records module
- Vehicles module
- File upload to MinIO
- Push notifications via ntfy
- OAuth (Google/Facebook)
- Email notifications
- WebSocket real-time updates
- Payment gateway integration

---

**Version**: 1.0.0
**Last Updated**: December 14, 2024
**Author**: FROGIO Team
