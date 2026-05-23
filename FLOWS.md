# FROGIO Application - Comprehensive Flow Map

**Version:** 1.0  
**Date:** April 2, 2026  
**Scope:** Complete architecture for web-admin, mobile app, and backend systems

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Authentication & Authorization Flows](#authentication--authorization-flows)
3. [User Management](#user-management)
4. [Reports System](#reports-system)
5. [Citations System](#citations-system)
6. [Infractions System](#infractions-system)
7. [Medical Records](#medical-records)
8. [Vehicles & Fleet Management](#vehicles--fleet-management)
9. [Geofences System](#geofences-system)
10. [Panic Alerts & Emergency Response](#panic-alerts--emergency-response)
11. [GPS Tracking & Live Maps](#gps-tracking--live-maps)
12. [Notifications](#notifications)
13. [Dashboard & Analytics](#dashboard--analytics)
14. [Data Export & Reporting](#data-export--reporting)
15. [Real-time Features (WebSocket)](#real-time-features-websocket)

---

## Architecture Overview

### Technology Stack

**Backend:**
- **Runtime:** Node.js with Express.js
- **Database:** PostgreSQL (multi-tenant with schemas)
- **Real-time:** Socket.IO
- **Caching:** Redis (optional)
- **File Storage:** MinIO
- **Authentication:** JWT (access + refresh tokens)

**Web Admin:**
- **Framework:** Next.js 15 (App Router)
- **UI:** React + Tailwind CSS + Headless UI
- **State:** Client-side with React hooks + fetch
- **Maps:** Leaflet
- **Data Export:** XLSX library

**Mobile:**
- **Framework:** Flutter 3+
- **State Management:** BLoC pattern (flutter_bloc)
- **API Client:** Dio
- **Location:** Geolocator + Geocoding
- **Maps:** flutter_map
- **Local Storage:** SharedPreferences

### Core Middleware Chain

```
Request → CORS/Security (Helmet) → JSON Parser → Auth Middleware → Role Guard → Controller
```

**Auth Middleware** (`/apps/backend/src/middleware/auth.middleware.ts`):
- Extracts Bearer token from `Authorization` header
- Validates JWT signature with `JWT_SECRET`
- Attaches user data to request: `{ userId, email, role, tenantId }`
- Returns 401 if missing/invalid token

**Role Guard**:
- Applied per-route to restrict access by role
- Roles: `citizen`, `inspector`, `admin`, `health_worker`
- Returns 403 if user role not in allowed list

### Tenant Architecture

- **Multi-tenant:** Each tenant is a separate PostgreSQL schema
- **Tenant ID:** Passed via `X-Tenant-ID` header (default: `santa_juana`)
- **Isolation:** All queries scoped to tenant schema using `"${tenantId}".table_name`
- **Database:** Single PostgreSQL instance with multiple schemas per tenant

---

## Authentication & Authorization Flows

### 1. Login Flow (Web Admin + Mobile)

#### Entry Points
- **Web:** `/login` (page) → `/api/auth/login` (route) → Backend `/api/auth/login`
- **Mobile:** `LoginScreen` → `AuthBloc` → `SignInUser` usecase → Backend API

#### Process Flow

```
User Input
  ↓
[Client] POST /api/auth/login { email, password }
  ↓
[Web Route] /api/auth/login (NextJS proxy)
  ├─ Validate email/password present
  ├─ Forward to Backend: POST ${API_URL}/api/auth/login
  │   Headers: X-Tenant-ID: santa_juana
  ├─ Backend AuthService.login()
  │   ├─ Query: SELECT * FROM "${tenantId}".users WHERE email = $1
  │   ├─ Compare password with bcrypt
  │   ├─ Check is_active flag
  │   ├─ Generate JWT tokens:
  │   │   ├─ accessToken (15 min expiry)
  │   │   └─ refreshToken (7 days expiry)
  │   └─ Return user data + tokens
  ├─ Set HTTP-only cookies:
  │   ├─ accessToken (15 min, httpOnly, sameSite=lax)
  │   └─ refreshToken (7 days, httpOnly, sameSite=lax)
  ├─ Return: { success: true, user: {...} }
  ↓
[Client] Store tokens in cookies/secure storage
  ↓
Redirect to /dashboard
```

#### API Endpoint
- **Backend:** `POST /api/auth/login`
- **Controller:** `AuthController.login()`
- **Service:** `AuthService.login(data, tenantId)`
- **Authorization:** Public (no auth required)
- **Request:** `{ email: string, password: string }`
- **Response:** `{ user: {...}, accessToken: string, refreshToken: string }`
- **Errors:**
  - 400: Tenant ID required in headers
  - 401: Invalid credentials / User inactive

#### Validation Rules
- Password: Hashed with bcrypt (12 rounds)
- RUT: Basic format validation (Chilean ID)
- Email: Case-sensitive
- Active Check: Users with `is_active=false` cannot login

#### Token Structure (JWT Payload)
```json
{
  "userId": "uuid",
  "email": "user@example.com",
  "role": "inspector|admin|citizen|health_worker",
  "tenantId": "santa_juana",
  "iat": 1234567890,
  "exp": 1234567890
}
```

---

### 2. Register Flow (Web + Mobile)

#### Entry Points
- **Web:** `/users/new` → `/api/users/create` → Backend `/api/auth/register`
- **Mobile:** `RegisterScreen` → `AuthBloc` → `RegisterUser` usecase

#### Process Flow

```
User Submission
  ↓
[Client] POST /api/users/create {
  email, password, first_name, last_name, rut, role
}
  ↓
[Web Route] Validate fields
  ├─ Check: password >= 8 chars
  ├─ Check: email valid format
  ├─ Check: all required fields present
  ├─ Forward to Backend: POST /api/auth/register
  │   Headers: 
  │   ├─ Authorization: Bearer {token}
  │   ├─ X-Tenant-ID: santa_juana
  ├─ Backend AuthService.register()
  │   ├─ Validate RUT format
  │   ├─ Check: user not exists (email OR rut)
  │   ├─ Hash password with bcrypt (12 rounds)
  │   ├─ INSERT INTO "${tenantId}".users
  │   ├─ Generate tokens
  │   └─ Return user data + tokens
  ├─ Set cookies (same as login)
  ↓
Return: { user, accessToken, refreshToken }
  ↓
Redirect to /dashboard
```

#### API Endpoint
- **Backend:** `POST /api/auth/register`
- **Authorization:** Public (no auth required) - but tenant ID mandatory
- **Request:** `{ email, password, rut, firstName, lastName, phone?, role }`
- **Response:** Same as login
- **Errors:**
  - 400: User exists / Invalid RUT / Missing fields
  - 400: Tenant ID required

#### Validation Rules
- **RUT:** Chilean format validation (checks verification digit)
- **Password:** Minimum 8 characters, hashed with bcrypt 12 rounds
- **Email:** Must be unique within tenant
- **RUT:** Must be unique within tenant
- **Role:** Default is `citizen` if not provided

---

### 3. Token Refresh Flow

#### Entry Points
- **Web:** Automatic when accessToken expires
- **Mobile:** `AuthBloc` watches token expiry

#### Process Flow

```
Access Token Expires
  ↓
[Client] POST /api/auth/refresh { refreshToken }
  ↓
[Web Route] Forward to Backend
  ├─ Backend AuthService.refreshToken()
  │   ├─ Verify refresh token JWT
  │   ├─ Check Redis blacklist (if available)
  │   ├─ Extract: userId, email, role, tenantId
  │   ├─ Generate new tokens
  │   └─ Return tokens
  ├─ Set new cookies
  ↓
Return: { accessToken, refreshToken }
  ↓
Continue with fresh token
```

#### API Endpoint
- **Backend:** `POST /api/auth/refresh`
- **Authorization:** Public (token in body)
- **Request:** `{ refreshToken: string }`
- **Response:** `{ accessToken, refreshToken }`
- **Errors:**
  - 401: Invalid/expired refresh token
  - 401: Token in blacklist (logout invalidation)

#### Token Revocation (Logout)
- Refresh token added to Redis blacklist with 7-day expiry
- Future refresh attempts rejected
- accessToken still valid until natural expiry (then blocked by blacklist)

---

### 4. Password Reset Flow

#### Entry Points
- **Web:** Login page → "¿Olvidaste tu contraseña?" → Alert dialog
- **Mobile:** LoginScreen with forgot password button

#### Process Flow

```
User Request Password Reset
  ↓
[Client] POST /api/auth/forgot-password { email }
  ↓
[Backend] AuthService.forgotPassword()
  ├─ Query: SELECT * FROM "${tenantId}".users WHERE email = $1
  ├─ Generate reset token (1 hour expiry, type='password_reset')
  ├─ Store in Redis: password_reset:{userId} = token
  ├─ Log token (or send via ntfy/email - TODO)
  ├─ ALWAYS return success (email enumeration prevention)
  ↓
Return: { message: 'Si el correo existe...' }
  ↓
[User] Receives link with reset token
  ↓
[Client] POST /api/auth/reset-password { token, password }
  ├─ Verify token JWT
  ├─ Check type='password_reset'
  ├─ Validate Redis: token matches stored value
  ├─ Hash new password
  ├─ UPDATE "${tenantId}".users SET password_hash = $1
  ├─ DELETE Redis key (token invalidated)
  ↓
Return: { message: 'Contraseña actualizada' }
```

#### API Endpoints
- **POST /api/auth/forgot-password**
  - Request: `{ email: string }`
  - Response: `{ message: string }`
  - Errors: 400 (invalid email format)

- **POST /api/auth/reset-password**
  - Request: `{ token: string, password: string }`
  - Response: `{ message: string }`
  - Errors:
    - 400: Password < 8 chars
    - 400: Token invalid / expired / already used

#### Security Considerations
- Reset token valid only 1 hour
- Token one-time use (deleted from Redis after use)
- Always return success message to prevent email enumeration
- Reset link should use secure token format

---

### 5. User Profile Management

#### Get Profile

```
[Authenticated] GET /api/auth/profile
  ↓
[Backend] AuthService.getProfile(userId, tenantId)
  ├─ Query: SELECT * FROM "${tenantId}".users WHERE id = $1
  ├─ Parse family_members JSON
  ↓
Return: {
  id, email, rut, firstName, lastName, phoneNumber,
  address, profileImageUrl, latitude, longitude,
  referenceNotes, familyMembers, role, createdAt, updatedAt
}
```

#### Update Profile

```
[Authenticated] PATCH /api/auth/profile { ...updates }
  ↓
[Backend] AuthService.updateProfile(userId, tenantId, data)
  ├─ Validate RUT if provided
  ├─ Build dynamic UPDATE query
  ├─ UPDATE "${tenantId}".users SET ...
  ├─ Parse responses
  ↓
Return: Updated user object
```

#### Web Routes
- **GET /profile** (protected, auth required)
- **PATCH /profile** (protected, auth required)

---

## User Management

### 1. Admin User CRUD

#### Admin Only Endpoints
All require `authMiddleware` + `roleGuard('admin')`

**Endpoints:**
```
GET    /api/users                    - List all users (with filters)
POST   /api/users                    - Create new user
GET    /api/users/:id                - Get user by ID
PATCH  /api/users/:id                - Update user
DELETE /api/users/:id                - Delete user (prevents self-delete)
PATCH  /api/users/:id/toggle-status  - Toggle is_active
PATCH  /api/users/:id/password       - Update password as admin
GET    /api/users/stats              - Get user statistics
```

#### Create User Flow

```
Admin POST /api/users { email, password, first_name, last_name, rut, role }
  ↓
[Validation]
  ├─ Check all required fields
  ├─ Validate password >= 8 chars
  ├─ Validate RUT format
  ├─ Check user not exists
  ↓
[Database]
  ├─ Hash password bcrypt(12)
  ├─ INSERT INTO "${tenantId}".users (
       email, password_hash, rut, first_name, last_name,
       phone, role, is_active, created_at, updated_at
     )
  ↓
Return: Created user (without password)
```

#### List Users Flow

```
GET /api/users?role=inspector&isActive=true&search=query
  ↓
[Validation]
  ├─ Extract query params
  ├─ Build dynamic WHERE clause
  ↓
[Database]
  ├─ Query with filters:
  │   ├─ role = $1 (optional)
  │   ├─ is_active = $2 (optional)
  │   ├─ email ILIKE '%query%' OR first_name ILIKE '%query%' (optional)
  ├─ ORDER BY created_at DESC
  ↓
Return: Array of users
```

#### Web Admin Interface

**Page:** `/users`
- Server-side data fetch on page load
- List view with filters (role, status, search)
- Action buttons: Edit, Delete, Toggle Status

**Page:** `/users/new`
- Form with fields: email, password, first_name, last_name, rut, phone, role
- Validation on client + server
- POST to `/api/users/create` (web proxy)

**Page:** `/users/[id]/edit`
- Fetch user data
- Update form
- Separate password change endpoint

---

## Reports System

### 1. Report Creation (Citizen + Inspector)

#### Entry Points
- **Web:** `/reports/[id]/edit` (inspector edit existing)
- **Mobile:** `EnhancedReportScreen` (citizen creates)

#### Process Flow

```
Citizen/Inspector POST /api/reports {
  title, description, type, priority,
  latitude?, longitude?, address?, images?
}
  ↓
[Backend] ReportsController.create()
  ├─ Validate type IN ('denuncia','sugerencia','emergencia','infraestructura','otro')
  ├─ Validate priority IN ('baja','media','alta','urgente')
  ├─ Check location fields if provided
  ├─ INSERT INTO "${tenantId}".reports (
       title, description, type, priority, status,
       user_id, latitude, longitude, address,
       created_at, updated_at
     ) VALUES (...)
  ├─ status = 'pendiente' (default)
  ├─ Create version history entry:
       INSERT INTO "${tenantId}".report_versions (...)
  ├─ Save images to MinIO if provided
  ↓
Return: Created report with id
```

#### API Endpoint
- **Backend:** `POST /api/reports`
- **Authorization:** authMiddleware (all authenticated users)
- **Request:**
  ```json
  {
    "title": "string",
    "description": "string",
    "type": "denuncia|sugerencia|emergencia|infraestructura|otro",
    "priority": "baja|media|alta|urgente",
    "latitude": number,
    "longitude": number,
    "address": "string",
    "images": ["base64_or_url"]
  }
  ```
- **Response:**
  ```json
  {
    "id": "uuid",
    "title": "...",
    "type": "...",
    "status": "pendiente",
    "user_id": "uuid",
    "created_at": "...",
    ...
  }
  ```

### 2. Report Listing & Filtering

#### Citizens See Own Reports

```
GET /api/reports
  ↓
[Backend] ReportsController.findAll()
  ├─ If role='citizen': userId = req.user.userId
  ├─ Query: SELECT * FROM "${tenantId}".reports
  │  WHERE user_id = userId (citizens only)
  │  AND status = $1 (if provided)
  │  AND type = $2 (if provided)
  ├─ ORDER BY created_at DESC
  ↓
Return: Reports array
```

#### Inspectors/Admins See All

```
GET /api/reports?status=pendiente&type=emergencia
  ↓
[Backend] ReportsController.findAll()
  ├─ If role='inspector'|'admin': No user_id filter
  ├─ Query: SELECT * FROM "${tenantId}".reports
  │  WHERE status = $1 AND type = $2 (if provided)
  ├─ ORDER BY priority DESC, created_at DESC
  ↓
Return: All matching reports
```

### 3. Report Update (Inspector/Admin Only)

#### Process Flow

```
Inspector PATCH /api/reports/:id {
  title?, description?, status?, priority?
}
  ↓
[Backend] ReportsController.update()
  ├─ Get current report state
  ├─ Build UPDATE query with provided fields
  ├─ UPDATE "${tenantId}".reports SET ...
  ├─ Create version history:
       INSERT INTO "${tenantId}".report_versions (
         report_id, version_number, changes, modified_by,
         created_at
       )
  ├─ Emit Socket.IO event: 'report:updated'
  ├─ Send notifications if status changed
  ↓
Return: Updated report
```

#### Version History

```
GET /api/reports/:id/versions
  ├─ Authorization: roleGuard('inspector', 'admin')
  ├─ Query: SELECT * FROM "${tenantId}".report_versions
  │  WHERE report_id = $1
  │  ORDER BY version_number DESC
  ↓
Return: Array of versions with change details
```

### 4. Report Status Transitions

**Valid Statuses:** `pendiente` → `en_proceso` → `resuelto` | `rechazado`

```
Workflow:
1. Created as 'pendiente'
2. Inspector assigns & changes to 'en_proceso'
3. Inspector resolves: 'resuelto' or 'rechazado'
4. Citizens can view at any stage
```

### 5. Web Admin Report Interface

**Page:** `/reports`
- Server-side list fetch
- Client-side filters: status, type, search
- Data: auto-refresh every 30s
- Actions: View detail, Assign to inspector, Change status

**Page:** `/reports/[id]`
- Report detail with edit form
- Version history tab
- Inspector selector for assignment
- Map with report location
- Status update dropdown

---

## Citations System

### 1. Citation Creation (Inspector/Admin)

#### Entry Points
- **Web:** `/citations/new` → Form submission
- **Mobile:** `CreateCitationScreen` (inspector)

#### Process Flow

```
Inspector POST /api/citations {
  citation_type: 'advertencia'|'citacion',
  target_type: 'persona'|'domicilio'|'vehiculo'|'comercio'|'otro',
  target_name?, target_rut?, target_address?, target_phone?, target_plate?,
  location_address,
  reason,
  details?,
  images?
}
  ↓
[Backend] CitationsController.create()
  ├─ Validate citation_type IN ('advertencia', 'citacion')
  ├─ Validate target_type IN ('persona', 'domicilio', 'vehiculo', 'comercio', 'otro')
  ├─ Generate citation_number (auto-increment)
  ├─ INSERT INTO "${tenantId}".citations (
       citation_type, target_type, target_name, target_rut,
       target_address, target_phone, target_plate,
       location_address, reason, details, citation_number,
       issuer_id, created_at, updated_at
     )
  ├─ Save images to MinIO
  ├─ Create version history
  ├─ Update vehicle fines if target_plate matched
  ↓
Return: Created citation
```

#### API Endpoint
- **Backend:** `POST /api/citations`
- **Authorization:** roleGuard('inspector', 'admin')
- **Request:**
  ```json
  {
    "citation_type": "advertencia|citacion",
    "target_type": "persona|domicilio|vehiculo|comercio|otro",
    "target_name": "string (optional)",
    "target_rut": "string (optional)",
    "target_address": "string (optional)",
    "target_phone": "string (optional)",
    "target_plate": "string (optional)",
    "location_address": "string (required)",
    "reason": "string (required)",
    "details": "string",
    "images": ["url|base64"]
  }
  ```

### 2. Bulk Import (Excel)

#### Process Flow

```
Admin POST /api/citations/import (multipart/form-data)
  ├─ File: .xlsx with columns:
  │   ├─ citation_type
  │   ├─ target_type
  │   ├─ target_name
  │   ├─ target_rut
  │   ├─ target_plate
  │   ├─ location_address
  │   └─ reason
  ↓
[Backend] CitationsController.bulkImport()
  ├─ Parse XLSX file
  ├─ For each row:
  │   ├─ Validate fields
  │   ├─ INSERT INTO citations
  │   ├─ Track errors
  ├─ Return result: { imported: N, errors: [] }
  ↓
Return: { imported: number, errors: [] }
```

#### Web Admin Upload
**Page:** `/citations`
- Upload button opens file picker
- Drag-drop zone for .xlsx files
- Import progress modal
- Success/error summary

### 3. Citation Listing & Search

```
GET /api/citations?search=plate&filterType=citacion
  ├─ Authorization: authMiddleware
  ├─ Citizens: See no citations (filtered in controller)
  ├─ Inspectors/Admins: See all or own citations
  ├─ Query with ILIKE for search on:
  │   ├─ target_name
  │   ├─ target_rut
  │   ├─ target_plate
  │   ├─ reason
  ├─ Filter by citation_type if provided
  ↓
Return: Array of citations with issuer details
```

### 4. Citation Version History

```
GET /api/citations/:id/versions
  ├─ Authorization: authMiddleware
  ├─ Query: SELECT * FROM "${tenantId}".citation_versions
  │  WHERE citation_id = $1
  │  ORDER BY version_number DESC
  ↓
Return: Array of versions
```

### 5. Web Admin Citations Interface

**Page:** `/citations`
- Auto-refresh list every 30s
- Search by name/plate/RUT
- Filter by citation type (advertencia/citacion)
- Export to Excel button
- Create new citation button

**Page:** `/citations/new`
- Form with all citation fields
- Target type selector (changes visible fields)
- Image upload
- Location address with Google Maps integration

**Page:** `/citations/[id]`
- View citation details
- Display images gallery
- Version history tab
- Edit option for inspectors
- Print citation button

---

## Infractions System

### 1. Infraction Creation (Inspector/Admin)

#### Entry Points
- **Web:** `/infractions/new`
- **Mobile:** Inspector dashboard

#### Process Flow

```
Inspector POST /api/infractions {
  infraction_type, severity, vehicle_plate?, person_name?,
  description, location, evidence?
}
  ↓
[Backend] InfractionsController.create()
  ├─ Validate infraction_type
  ├─ Validate severity IN ('leve', 'grave', 'muy_grave')
  ├─ INSERT INTO "${tenantId}".infractions (
       infraction_type, severity, vehicle_plate, person_name,
       description, location, status, created_by,
       created_at, updated_at
     )
  ├─ Save evidence files
  ├─ status = 'registrada' (default)
  ↓
Return: Created infraction
```

#### API Endpoint
- **Backend:** `POST /api/infractions`
- **Authorization:** roleGuard('inspector', 'admin')

### 2. Infraction Listing

```
GET /api/infractions
  ├─ Citizens: Return empty array
  ├─ Inspectors/Admins: All infractions
  ├─ Optional filters: status, severity
  ↓
Return: Infractions array
```

### 3. Infraction Statistics

```
GET /api/infractions/stats
  ├─ Authorization: authMiddleware
  ├─ Query aggregations:
  │   ├─ COUNT(*) total
  │   ├─ COUNT(*) by status
  │   ├─ COUNT(*) by severity
  │   ├─ COUNT(*) by type
  ↓
Return: { total, byStatus, bySeverity, byType }
```

---

## Medical Records

### 1. Medical Record Creation

#### Entry Points
- **Web:** `/medical-records/new` (health worker/admin)
- **Mobile:** Health worker feature

#### Process Flow

```
Health Worker POST /api/medical-records {
  patient_id, condition, treatment, notes?, medications?
}
  ↓
[Backend] MedicalRecordsController.create()
  ├─ Validate required fields
  ├─ INSERT INTO "${tenantId}".medical_records (
       patient_id, condition, treatment, notes,
       medications, recorded_by, created_at
     )
  ├─ Attach to user profile
  ↓
Return: Created record
```

#### API Endpoint
- **Backend:** `POST /api/medical-records`
- **Authorization:** authMiddleware (citizens, health workers)

### 2. Medical Record Access Control

```
GET /api/medical-records/:id
  ├─ Citizens: Own records only
  ├─ Health workers/Admins: All records
  ├─ Inspectors: Can view for emergency context
  ↓
Return: Record details
```

### 3. Medical Records in Panic Context

```
During Panic Alert Response:
  ├─ Responder can view medical records
  ├─ Shows: Conditions, allergies, medications
  ├─ Quick reference in emergency
  ├─ Read-only access
```

---

## Vehicles & Fleet Management

### 1. Vehicle Registration

#### Entry Points
- **Web:** `/vehicles/new` → Form
- **Mobile:** Citizen or admin registration

#### Process Flow

```
Admin POST /api/vehicles {
  plate, brand, model, year?, color?,
  vehicle_type, owner_rut, owner_first_name,
  owner_last_name, ownership_type?, vehicle_status?
}
  ↓
[Backend] VehiclesController.create()
  ├─ Validate required fields
  ├─ Check: plate unique within tenant
  ├─ INSERT INTO "${tenantId}".vehicles (
       plate, brand, model, year, color, vehicle_type,
       owner_rut, owner_first_name, owner_last_name,
       ownership_type, vehicle_status, is_active,
       created_at
     )
  ├─ Initialize vehicle_status = 'activo'
  ↓
Return: Created vehicle
```

#### API Endpoint
- **Backend:** `POST /api/vehicles`
- **Authorization:** authMiddleware (all users can register)
- **Unique Constraint:** plate + tenantId

### 2. Vehicle Search

```
GET /api/vehicles/plate/:plate?tenantId=santa_juana
  ├─ Authorization: roleGuard('inspector', 'admin')
  ├─ Query: SELECT * FROM "${tenantId}".vehicles
  │  WHERE UPPER(plate) = UPPER($1)
  ├─ Return immediately if found
  ↓
Return: Vehicle data or 404
```

**Use Case:** Inspector checks vehicle plate during traffic stops

### 3. Vehicle Usage Logs

```
START USAGE:
  Inspector POST /api/vehicles/logs/start { vehicle_id }
  ├─ Authorization: roleGuard('inspector', 'admin')
  ├─ INSERT INTO "${tenantId}".vehicle_usage_logs (
       vehicle_id, inspector_id, start_time, status
     )
  ├─ status = 'active'
  ├─ Get GPS coordinates for start location
  ↓
Return: { logId, vehicle_id, start_time, start_location }

END USAGE:
  Inspector PATCH /api/vehicles/logs/:logId/end {
    latitude, longitude, mileage?, notes?
  }
  ├─ UPDATE "${tenantId}".vehicle_usage_logs
  │  SET end_time = NOW(), end_latitude, end_longitude,
  │      status = 'completed'
  ├─ Calculate distance traveled
  ├─ Calculate fuel consumption
  ↓
Return: Updated log with statistics
```

### 4. Vehicle Status Management

```
Admin Actions:
  ├─ Toggle active: PATCH /api/vehicles/:id (is_active = true/false)
  ├─ Update status: PATCH /api/vehicles/:id
  │  (vehicle_status = 'activo' | 'dado_de_baja' | 'en_espera_de_remate')
  ├─ Change ownership
  ├─ Update maintenance notes
```

### 5. Web Admin Fleet Interface

**Page:** `/fleet`
- Real-time map with vehicle positions
- Vehicle list with status
- Filter by status/type
- Quick actions: Start/End usage

**Page:** `/fleet/history`
- Historical usage logs
- Search by vehicle/date range
- Distance traveled, fuel consumed
- Export to CSV

**Page:** `/fleet/stats`
- Total vehicles
- Active vs inactive
- Usage hours this month
- Cost analysis
- Maintenance due

---

## Geofences System

### 1. Geofence Creation (Admin Only)

#### Entry Points
- **Web:** `/fleet/geofences` → Create form

#### Process Flow

```
Admin POST /api/geofences {
  name, geofence_type: 'circle'|'polygon',
  
  // Circle:
  center_lat, center_lng, radius_meters,
  
  // Polygon:
  polygon_coordinates: [ {lat, lng}, ... ]
}
  ↓
[Backend] GeofencesController.create()
  ├─ Validate geofence_type
  ├─ If circle: validate center + radius
  ├─ If polygon: validate coordinates closed path
  ├─ INSERT INTO "${tenantId}".geofences (
       name, geofence_type, center_lat, center_lng,
       radius_meters, polygon_coordinates,
       is_active, created_at
     )
  ├─ Initialize is_active = true
  ├─ Cache geofence for quick lookups
  ↓
Return: Created geofence
```

#### API Endpoint
- **Backend:** `POST /api/geofences`
- **Authorization:** roleGuard('admin')

### 2. Geofence Checks

```
POST /api/geofences/check {
  latitude, longitude
}
  ├─ Get all active geofences
  ├─ For each geofence:
  │   ├─ If circle: distance = haversine(lat,lng, center_lat, center_lng)
  │   │            inside = distance <= radius_meters
  │   ├─ If polygon: inside = point_in_polygon(lat, lng, coordinates)
  ├─ Return: [ { geofence_id, name, inside, type } ]
  ↓
Return: Array of geofence intersections
```

**Use Case:** Check if GPS point is inside restricted zones

### 3. Geofence Events

```
When Vehicle Enters/Exits:
  ├─ Track: enter_event, exit_event, dwell_time
  ├─ Store in "${tenantId}".geofence_events
  ├─ Emit Socket.IO: 'geofence:alert'
  ├─ Send notifications if restricted zone
  ├─ Create incident report if needed
```

### 4. Web Admin Geofences

**Page:** `/fleet/geofences`
- Map with geofence visualization
- List of active geofences
- Create/Edit/Delete actions
- Recent events log

---

## Panic Alerts & Emergency Response

### 1. Panic Alert Creation (Any Authenticated User)

#### Entry Points
- **Mobile:** Emergency button on home screen
- **Web:** Not available (mobile-first feature)

#### Process Flow

```
Citizen/Inspector POST /api/panic {
  latitude, longitude, address?, emergency_type?
}
  ↓
[Backend] PanicController.create()
  ├─ Validate location coordinates
  ├─ INSERT INTO "${tenantId}".panic_alerts (
       user_id, latitude, longitude, address,
       status, created_at, updated_at
     )
  ├─ status = 'active'
  ├─ Emit Socket.IO: 'panic:alert' to responders
  ├─ Send SMS/Push notifications to inspectors
  ├─ Create incident record
  ├─ Start background tracking (every 5s location update)
  ↓
Return: { alertId, ... }
```

#### API Endpoint
- **Backend:** `POST /api/panic`
- **Authorization:** authMiddleware (all authenticated)
- **Request:**
  ```json
  {
    "latitude": number (required),
    "longitude": number (required),
    "address": "string (optional)",
    "emergency_type": "accident|violence|fire|medical|other (optional)"
  }
  ```
- **Response:**
  ```json
  {
    "id": "uuid",
    "user_id": "uuid",
    "status": "active",
    "latitude": number,
    "longitude": number,
    "created_at": "...",
    ...
  }
  ```

### 2. Panic Alert Response (Inspector/Admin)

#### Get Active Alerts

```
Inspector GET /api/panic/active
  ├─ Authorization: roleGuard('inspector', 'admin')
  ├─ Query: SELECT * FROM "${tenantId}".panic_alerts
  │  WHERE status IN ('active', 'responding')
  │  ORDER BY created_at ASC
  ├─ Include caller location, medical records
  ↓
Return: [ alerts with full context ]
```

#### Respond to Alert

```
Inspector PATCH /api/panic/:id/respond {
  response_notes?: "string"
}
  ├─ UPDATE "${tenantId}".panic_alerts
  │  SET status = 'responding', responder_id = $1,
  │      response_time = NOW()
  ├─ Emit Socket.IO: 'panic:responded' to caller
  ├─ Send notification: "Inspector en camino"
  ├─ Start tracking responder location
  ↓
Return: Updated alert
```

#### Resolve Alert

```
Inspector PATCH /api/panic/:id/resolve {
  resolution_notes: "string"
}
  ├─ UPDATE "${tenantId}".panic_alerts
  │  SET status = 'resolved', resolution_notes = $1,
  │      resolved_at = NOW()
  ├─ Create incident report
  ├─ Emit Socket.IO: 'panic:resolved'
  ├─ Stop location tracking
  ↓
Return: Updated alert with incident reference
```

### 3. Mobile Panic Flow

```
[Mobile] User Taps Emergency Button
  ├─ Request current location (GPS)
  ├─ Show confirmation: "¿Enviar alerta de emergencia?"
  ├─ Countdown: 10 seconds (tap to cancel)
  ├─ Automatic location sharing (every 5 seconds)
  ├─ Display "Respuesta en camino" when inspector responds
  ├─ Show inspector location on map (if permission granted)
  ├─ Allow call/SMS shortcut
  ├─ Cancel alert button at any time
```

#### Cancel Alert

```
Citizen PATCH /api/panic/:id/cancel
  ├─ User must be owner OR admin
  ├─ UPDATE status = 'cancelled'
  ├─ Stop location tracking
  ├─ Notify responders if en route
  ↓
Return: Cancelled alert
```

### 4. Web Admin Panic Dashboard

**Feature:** Responder Console
- Map showing active panic alerts
- Inspector locations
- Response time metrics
- Call/SMS integration

---

## GPS Tracking & Live Maps

### 1. GPS Point Submission (Inspector)

#### Batch Upload

```
Inspector POST /api/gps/batch {
  points: [
    { vehicleId, latitude, longitude, speed?, heading?, timestamp },
    ...
  ]
}
  ↓
[Backend] GpsTrackingController.insertBatch()
  ├─ For each point:
  │   ├─ Validate coordinates
  │   ├─ INSERT INTO "${tenantId}".gps_points (
  │        vehicle_id, latitude, longitude,
  │        speed, heading, timestamp, accuracy
  │      )
  │   ├─ Check geofences (alert if inside restricted)
  │   ├─ Update latest position cache
  ├─ Emit Socket.IO: 'fleet:update' with latest positions
  ↓
Return: { inserted: N, errors: [] }
```

#### Real-time Position Updates

```
[Mobile] Background Service (every 30s)
  ├─ Request GPS location
  ├─ Collect: latitude, longitude, speed, heading, accuracy
  ├─ Batch 20 points
  ├─ POST /api/gps/batch
  ├─ Handle offline: queue points, retry when online
```

### 2. Live Positions

```
GET /api/gps/vehicles/live
  ├─ Authorization: authMiddleware
  ├─ Query latest from cache (Redis):
  │   ├─ SELECT DISTINCT ON (vehicle_id)
  │   ├─ FROM "${tenantId}".gps_points
  │   ├─ ORDER BY vehicle_id, timestamp DESC
  ├─ Include: vehicle_id, plate, latitude, longitude,
  │   speed, heading, last_update, inspector_name
  ↓
Return: [ { vehicleId, latitude, longitude, ... } ]
```

### 3. Route History

```
GET /api/gps/vehicle/:vehicleId/history?
    &startDate=2024-01-01&endDate=2024-01-31
  ├─ Authorization: authMiddleware
  ├─ Query: SELECT * FROM "${tenantId}".gps_points
  │  WHERE vehicle_id = $1
  │  AND timestamp BETWEEN $2 AND $3
  │  ORDER BY timestamp ASC
  ├─ Include: latitude, longitude, speed, timestamp
  ├─ Limit: max 10,000 points per request
  ↓
Return: [ points ] for route drawing
```

### 4. Web Admin Live Map

**Page:** `/live-map`
- Real-time vehicle positions (Socket.IO)
- Vehicle list sidebar
- Geofences overlay
- Incident markers
- Search/filter vehicles

**Page:** `/fleet/history`
- Date range picker
- Route playback (animate path)
- Speed graph
- Statistics: distance, duration, avg speed

---

## Notifications

### 1. Notification Types

```
Types:
  ├─ alert: Urgent (panic, incident)
  ├─ report: Report status update
  ├─ citation: Citation issued
  ├─ system: System announcements
  ├─ infraction: Infraction recorded
  └─ maintenance: Vehicle maintenance due
```

### 2. Notification Creation

```
Trigger Events:
  ├─ Report created → Notify inspectors
  ├─ Report assigned → Notify assigned inspector
  ├─ Report status changed → Notify creator + inspector
  ├─ Citation issued → Notify target (if citizen)
  ├─ Panic alert → Notify all available inspectors
  ├─ Geofence breach → Notify admin
  ├─ Low fuel warning → Notify vehicle owner
```

#### Flow

```
[Event] Report status changed to 'resuelto'
  ├─ ReportsService emits event
  ├─ NotificationsService.create({
       userId, type: 'report',
       title: 'Reporte Resuelto',
       message: 'Tu reporte fue resuelto',
       referenceId: reportId,
       referenceType: 'report'
     })
  ├─ INSERT INTO "${tenantId}".notifications
  ├─ Send Push notification (if subscribed)
  ├─ Send SMS (if critical, admin only)
```

#### API Endpoints

```
GET /api/notifications
  ├─ Authorization: authMiddleware
  ├─ Query: SELECT * FROM "${tenantId}".notifications
  │  WHERE user_id = $1 AND deleted_at IS NULL
  │  ORDER BY created_at DESC
  ├─ Limit: last 50
  ↓
Return: [ notifications ]

GET /api/notifications/unread/count
  ├─ Query: COUNT(*) WHERE user_id = $1 AND is_read = false
  ↓
Return: { unreadCount: number }

PATCH /api/notifications/:id/read
  ├─ UPDATE notifications SET is_read = true WHERE id = $1
  ↓
Return: Updated notification

PATCH /api/notifications/read-all
  ├─ UPDATE notifications SET is_read = true WHERE user_id = $1
  ↓
Return: { updated: number }

DELETE /api/notifications/:id
  ├─ UPDATE notifications SET deleted_at = NOW()
  ↓
Return: { success: true }
```

### 3. Push Notifications (Mobile)

```
Subscribe Flow:
  [Mobile] NotificationManager.subscribeToUserTopics(userId, role)
  ├─ FCM: Subscribe to topics
  │   ├─ user_{userId}
  │   ├─ role_{role}
  │   ├─ tenant_{tenantId}
  ├─ Listen to incoming messages

Receive Flow:
  [Backend] Sends FCM message to topic: user_{userId}
  ├─ [Mobile] Handler receives in background
  ├─ Parse: title, body, reference
  ├─ Show local notification
  ├─ Navigate to relevant screen on tap
```

---

## Dashboard & Analytics

### 1. Admin Dashboard

```
GET /api/dashboard (via /dashboard page)
  ├─ Server-side fetch parallel requests:
  │   ├─ GET /api/reports (all recent)
  │   ├─ GET /api/citations (stats)
  │   ├─ GET /api/users/stats
  │   ├─ GET /api/vehicles (count)
  ├─ Return aggregated data
  ↓
Render Dashboard with:
  ├─ Total reports (by status)
  ├─ Recent citations
  ├─ User count by role
  ├─ Active vehicles
  ├─ Alert summary
  ├─ Quick actions
```

### 2. Statistics Endpoints

```
GET /api/users/stats
  ├─ { total, byRole, active, inactive }

GET /api/citations/stats
  ├─ { total, byType, thisMonth, issued_by_me }

GET /api/infractions/stats
  ├─ { total, bySeverity, byStatus, thisMonth }

GET /api/reports/stats (implicit via list)
  ├─ { total, byStatus, byType, byPriority }

GET /api/panic/stats
  ├─ { total_active, total_resolved, avg_response_time,
       monthly_count, status_distribution }

GET /api/gps/stats (admin only)
  ├─ { vehicles_tracked, active_inspectors,
       total_distance_month, avg_speed, geofence_violations }
```

---

## Data Export & Reporting

### 1. Export Endpoints (Admin Only)

```
GET /api/exports/reports (produces CSV/XLSX)
  ├─ Query all reports
  ├─ Include: id, title, type, status, created_at,
  │   creator_name, assigned_inspector
  ├─ Set headers: Content-Type: application/xlsx
  ├─ Return file stream

GET /api/exports/citations
  ├─ Include: id, number, type, target_name, target_plate,
  │   reason, issued_by, issued_date

GET /api/exports/users
  ├─ Include: id, email, role, first_name, last_name,
  │   created_at, is_active

GET /api/exports/vehicles
  ├─ Include: id, plate, brand, model, owner_name,
  │   vehicle_status, created_at

GET /api/exports/statistics
  ├─ Generate summary report:
  │   ├─ Period: last 30 days
  │   ├─ Reports: total, by status
  │   ├─ Citations: total, by type
  │   ├─ Users: count by role
  │   ├─ Response times: avg, max, min
  │   ├─ Vehicles: utilization, distance
```

### 2. Web Admin Export Interface

**Page:** `/reports`, `/citations`, `/vehicles`
- Export button: Downloads XLSX
- Client-side library: `XLSX` (xlsx package)
- Includes: filename with date, formatted headers

---

## Real-time Features (WebSocket)

### 1. Socket.IO Server Configuration

**Namespaces:**
- `/fleet` - Fleet tracking
- `/` - General notifications

### 2. Fleet Namespace Events

```
[Mobile Inspector Connects]
  socket.on('join:tenant', tenantId)
  ├─ socket.join(`tenant:${tenantId}`)
  ├─ Can now receive fleet updates for this tenant

[Mobile Inspector Joins Specific Vehicle]
  socket.on('join:vehicle', vehicleId)
  ├─ socket.join(`vehicle:${vehicleId}`)
  ├─ Can receive detailed tracking for this vehicle

[Server Broadcasts Position Update]
  io.of('/fleet').to(`tenant:${tenantId}`).emit('fleet:update', {
    vehicleId, latitude, longitude, speed, timestamp
  })
  ├─ All connected clients in tenant receive update

[Web Admin Listening]
  socket.on('fleet:update', (data) => {
    // Update map markers, refresh positions
  })
```

### 3. Notification Events

```
[Server Sends Report Update]
  io.to(`user:${userId}`).emit('report:updated', {
    reportId, status, timestamp, updatedBy
  })

[Report Created]
  io.to(`role:inspector`).emit('report:created', {
    reportId, title, type, priority
  })

[Panic Alert Triggered]
  io.to(`role:inspector`).emit('panic:alert', {
    alertId, userId, location, userPhone, userMedicalInfo
  })
```

### 4. Web Admin Real-time Updates

**Fleet Page:**
- Listens to `/fleet` namespace
- Auto-refresh vehicle positions from Socket.IO
- Updates map markers in real-time
- No polling needed

**Reports Page:**
- Listens to general notifications
- Auto-refresh when reports updated
- Show toast notifications

---

## Mobile App Architecture

### 1. BLoC State Management

```
Flow: Event → BLoC → Service → Repository → API → Response

[UI] User Action
  ↓
[BLoC] emit(AuthEvent)
  ├─ on<SignInEvent>()
  ├─ Service.signIn(email, password)
  ├─ Repository.login()
  ├─ API call
  ├─ Handle response/error
  ↓
[State] emit(Authenticated(user)) | emit(AuthError(message))
  ↓
[UI] BlocListener/BlocBuilder rebuilds
```

### 2. Features Architecture

```
Each feature folder:
  lib/features/{feature}/
  ├─ data/
  │   ├─ datasources/ (API calls)
  │   └─ repositories/ (implements domain repository)
  ├─ domain/
  │   ├─ entities/ (data models)
  │   ├─ repositories/ (abstract interfaces)
  │   └─ usecases/ (business logic)
  └─ presentation/
      ├─ bloc/ (state management)
      ├─ pages/ (screens)
      └─ widgets/ (reusable components)
```

### 3. Key Mobile Screens

```
1. SplashScreen
   ├─ Check auth status
   ├─ Navigate to Login or Dashboard

2. LoginScreen
   ├─ Email/password form
   ├─ Submit: AuthBloc.add(SignInEvent)
   ├─ Handle: Authenticated → Dashboard

3. DashboardScreen
   ├─ Role-based content:
   │   ├─ Citizen: My Reports, Panic Button, Notifications
   │   ├─ Inspector: Reports, Citations, Live Map, Vehicle Usage
   │   ├─ Admin: Statistics, User Management, Geofences

4. EnhancedReportDetailScreen
   ├─ Full report with map
   ├─ Version history
   ├─ Status updates (inspector only)
   ├─ Image gallery

5. PanicScreen
   ├─ Emergency button
   ├─ Location confirmation
   ├─ Live responder tracking
   ├─ Cancel alert option

6. InspectorMapScreen
   ├─ Live vehicle tracking
   ├─ Geofence visualization
   ├─ Quick action: Report incident
```

---

## Error Handling & Validation

### 1. Backend Error Responses

```
Format:
  {
    "error": "Human-readable message",
    "stack": "Stack trace (development only)"
  }

Status Codes:
  ├─ 201: Created successfully
  ├─ 400: Bad request (validation error)
  ├─ 401: Unauthorized (invalid/missing token)
  ├─ 403: Forbidden (insufficient permissions)
  ├─ 404: Not found
  ├─ 500: Internal server error
```

### 2. Validation Rules

**RUT (Chilean ID):**
- Format: XXXXXXXX-X or XX.XXX.XXX-X
- Verification digit calculated using weighted sum
- Must be unique per tenant

**Email:**
- Standard email format
- Case-sensitive in storage
- Must be unique per tenant

**Password:**
- Minimum 8 characters
- No format restrictions (allows special chars)
- Hashed with bcrypt (12 rounds)

**Coordinates:**
- Latitude: -90 to +90
- Longitude: -180 to +180
- Accuracy within 5-10 meters preferred

### 3. Field Validation Examples

```
Citation Creation:
  ✓ citation_type IN ('advertencia', 'citacion')
  ✓ target_type IN ('persona', 'domicilio', 'vehiculo', 'comercio', 'otro')
  ✓ location_address: required, min 5 chars
  ✓ reason: required, min 10 chars
  ✓ target_plate: alphanumeric if provided

Report Creation:
  ✓ title: required, min 10 chars, max 500 chars
  ✓ type: required, IN predefined list
  ✓ priority: required, IN ('baja', 'media', 'alta', 'urgente')
  ✓ latitude/longitude: valid coordinates if both provided
```

---

## Security Considerations

### 1. Authentication
- JWT tokens with configurable expiry
- Separate access (15 min) and refresh (7 days) tokens
- Token blacklist for logout (Redis)
- Password hashing with bcrypt (12 rounds)

### 2. Authorization
- Role-based access control (RBAC)
- Per-route role guards
- Data isolation by tenant (schema-level)
- User can only see own data (enforced in controller logic)

### 3. API Security
- CORS configured (configurable origins)
- Helmet.js for security headers
- Rate limiting: not implemented (consider adding)
- Input validation: all endpoints validate incoming data
- SQL Injection: Using parameterized queries throughout

### 4. Data Protection
- Email enumeration prevention in password reset (always success message)
- Location data: Only visible to authorized roles
- Medical records: Access control enforced
- PII: Stored in database, not in logs

### 5. Tenant Isolation
- Schema-level isolation (PostgreSQL schemas)
- All queries parameterized with tenant ID
- No cross-tenant data leakage possible
- Each tenant has own user roles/permissions

---

## Performance Optimizations

### 1. Caching Strategy
- Latest GPS positions cached in Redis
- Geofences cached for quick lookups
- Dashboard data: no caching (real-time)
- Reports list: no caching (frequently changing)

### 2. Database Indexes (Recommended)
```sql
CREATE INDEX idx_users_email_tenant ON "${tenantId}".users(email);
CREATE INDEX idx_reports_user_id ON "${tenantId}".reports(user_id);
CREATE INDEX idx_citations_plate ON "${tenantId}".citations(target_plate);
CREATE INDEX idx_gps_points_vehicle_time ON "${tenantId}".gps_points(vehicle_id, timestamp);
CREATE INDEX idx_geofences_active ON "${tenantId}".geofences(is_active);
```

### 3. Query Optimization
- Batch GPS point insertion (not one by one)
- Pagination for large lists (implement: limit 50, offset)
- SELECT only needed columns
- Pre-compute statistics (run nightly)

### 4. Web Admin Optimizations
- Server-side data fetch on page load
- Client-side auto-refresh every 30s (not real-time)
- Dynamic import for map components (avoid SSR)
- XLSX library: client-side export (no server CPU)

### 5. Mobile Optimizations
- GPS batch upload (every 20 points or 5 minutes)
- Offline queue: retry failed submissions
- Local caching: user profile, roles
- Background service: minimal wake-ups

---

## Deployment Checklist

### Backend
- [ ] Set environment variables (JWT_SECRET, API_URL, DATABASE_URL, REDIS_URL)
- [ ] Configure CORS origins (CORS_ORIGINS)
- [ ] Initialize PostgreSQL database with tenant schema
- [ ] Create MinIO buckets for file storage
- [ ] Set up Redis for token blacklist
- [ ] Configure email service (ntfy or other)
- [ ] Test health endpoint (/health)
- [ ] Enable database constraints auto-fix (runs on startup)

### Web Admin
- [ ] Set NEXT_PUBLIC_TENANT_ID and NEXT_PUBLIC_API_URL
- [ ] Build: `npm run build`
- [ ] Test authentication flow
- [ ] Verify all CRUD operations work
- [ ] Test file uploads (citations, reports)
- [ ] Test map components load
- [ ] Set cookie secure flag based on HTTPS

### Mobile
- [ ] Configure API URL in api_config.dart
- [ ] Set up Firebase Cloud Messaging for push notifications
- [ ] Configure Maps API keys
- [ ] Test location permissions
- [ ] Build and sign APK/IPA
- [ ] Test authentication and BLoC flows

---

## Monitoring & Logging

### Backend Logging
- HTTP request logging (method, URL)
- Error stack traces (development only)
- Database constraint auto-fix logs
- Service initialization logs

### Mobile Logging
- BLoC events and state changes
- Repository method calls
- Notification subscription status
- Location permission requests/denials

### Recommended Tools
- **Logs:** CloudWatch, ELK Stack, or Grafana Loki
- **Metrics:** Prometheus, New Relic
- **Errors:** Sentry
- **APM:** Datadog, New Relic

---

## Common User Journeys

### 1. Citizen Reporting an Issue
```
1. Open app → DashboardScreen
2. See "Report Issue" button
3. Tap → Navigate to report creation
4. Fill form: title, description, type, priority, location
5. Attach images (optional)
6. Submit → POST /api/reports
7. Redirect to my reports list
8. Receive notification when status changes
9. Can view report detail, version history
```

### 2. Inspector Responding to Panic
```
1. In app, receives push notification "Emergency Alert"
2. Open → PanicScreen shows alert location
3. Tap "Respond" → PATCH /api/panic/:id/respond
4. Caller notified: "Inspector en camino"
5. Inspector updates location (background GPS)
6. Arrive and taps "Resolve" → PATCH /api/panic/:id/resolve
7. Incident report created automatically
8. Caller receives "Incidente resuelto"
```

### 3. Admin Creating User
```
1. Web admin → /users/new
2. Fill form: email, password, name, RUT, role
3. Submit → POST /api/users/create
4. Validate and create via backend
5. User can login with credentials
6. Appears in users list
```

### 4. Inspector Issuing Citation
```
1. Mobile → InspectorDashboard
2. Tap "New Citation"
3. Select target type: vehicle
4. Scan plate or enter manually
5. Select citation type: citacion
6. Fill reason, location
7. Take photo evidence
8. Submit → POST /api/citations
9. Citation number generated
10. Print ticket for driver
```

---

## API Reference Summary

### Authentication Routes
| Method | Endpoint | Auth | Role Restrictions | Purpose |
|--------|----------|------|-------------------|---------|
| POST | /api/auth/login | No | - | Login user |
| POST | /api/auth/register | No | - | Register new user |
| POST | /api/auth/refresh | No | - | Refresh access token |
| POST | /api/auth/logout | No | - | Logout & blacklist token |
| GET | /api/auth/me | Yes | - | Get authenticated user |
| GET | /api/auth/profile | Yes | - | Get full user profile |
| PATCH | /api/auth/profile | Yes | - | Update profile |
| POST | /api/auth/forgot-password | No | - | Request password reset |
| POST | /api/auth/reset-password | No | - | Reset password with token |

### User Management Routes
| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| GET | /api/users | Yes | admin | List all users |
| POST | /api/users | Yes | admin | Create user |
| GET | /api/users/:id | Yes | admin | Get user by ID |
| PATCH | /api/users/:id | Yes | admin | Update user |
| DELETE | /api/users/:id | Yes | admin | Delete user |
| PATCH | /api/users/:id/toggle-status | Yes | admin | Toggle active |
| PATCH | /api/users/:id/password | Yes | admin | Update password |
| GET | /api/users/stats | Yes | admin | User statistics |

### Reports Routes
| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| GET | /api/reports | Yes | - | List reports (filtered) |
| POST | /api/reports | Yes | - | Create report |
| GET | /api/reports/:id | Yes | - | Get report detail |
| PATCH | /api/reports/:id | Yes | inspector, admin | Update report |
| DELETE | /api/reports/:id | Yes | admin | Delete report |
| GET | /api/reports/:id/versions | Yes | inspector, admin | Version history |

### Citations Routes
| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| GET | /api/citations | Yes | - | List citations |
| POST | /api/citations | Yes | inspector, admin | Create citation |
| GET | /api/citations/:id | Yes | - | Get citation |
| PATCH | /api/citations/:id | Yes | inspector, admin | Update citation |
| DELETE | /api/citations/:id | Yes | admin | Delete citation |
| GET | /api/citations/:id/versions | Yes | - | Version history |
| POST | /api/citations/import | Yes | admin | Bulk import |
| GET | /api/citations/stats | Yes | inspector, admin | Statistics |

### Infractions Routes
| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| GET | /api/infractions | Yes | - | List infractions |
| POST | /api/infractions | Yes | inspector, admin | Create infraction |
| GET | /api/infractions/:id | Yes | - | Get infraction |
| PATCH | /api/infractions/:id | Yes | inspector, admin | Update |
| DELETE | /api/infractions/:id | Yes | admin | Delete |
| GET | /api/infractions/stats | Yes | - | Statistics |

### Vehicles Routes
| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| GET | /api/vehicles | Yes | - | List vehicles |
| POST | /api/vehicles | Yes | - | Register vehicle |
| GET | /api/vehicles/:id | Yes | - | Get vehicle |
| PATCH | /api/vehicles/:id | Yes | - | Update vehicle |
| DELETE | /api/vehicles/:id | Yes | admin | Delete |
| GET | /api/vehicles/plate/:plate | Yes | inspector, admin | Search by plate |
| POST | /api/vehicles/logs/start | Yes | inspector, admin | Start usage |
| PATCH | /api/vehicles/logs/:logId/end | Yes | inspector, admin | End usage |
| GET | /api/vehicles/logs/:logId | Yes | inspector, admin | Get log |

### Panic Routes
| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| POST | /api/panic | Yes | - | Create alert |
| GET | /api/panic | Yes | inspector, admin | List all |
| GET | /api/panic/active | Yes | inspector, admin | Active alerts |
| GET | /api/panic/my-active | Yes | - | Own active alert |
| GET | /api/panic/:id | Yes | inspector, admin | Get alert |
| PATCH | /api/panic/:id/respond | Yes | inspector, admin | Respond |
| PATCH | /api/panic/:id/resolve | Yes | inspector, admin | Resolve |
| PATCH | /api/panic/:id/cancel | Yes | - | Cancel (owner only) |

### GPS Routes
| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| POST | /api/gps/batch | Yes | inspector, admin | Submit GPS points |
| GET | /api/gps/vehicles/live | Yes | - | Live positions |
| GET | /api/gps/vehicle/:vehicleId/live | Yes | - | Vehicle position |
| GET | /api/gps/vehicle/:vehicleId/history | Yes | - | Route history |
| GET | /api/gps/log/:logId/route | Yes | - | Log route |

### Geofences Routes
| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| GET | /api/geofences | Yes | - | List geofences |
| POST | /api/geofences | Yes | admin | Create |
| GET | /api/geofences/:id | Yes | - | Get |
| PATCH | /api/geofences/:id | Yes | admin | Update |
| DELETE | /api/geofences/:id | Yes | admin | Delete |
| POST | /api/geofences/check | Yes | - | Check point inside |

### Notifications Routes
| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| GET | /api/notifications | Yes | - | My notifications |
| GET | /api/notifications/unread/count | Yes | - | Unread count |
| PATCH | /api/notifications/:id/read | Yes | - | Mark read |
| PATCH | /api/notifications/read-all | Yes | - | Mark all read |
| DELETE | /api/notifications/:id | Yes | - | Delete |

### Export Routes
| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| GET | /api/exports/reports | Yes | admin | Export reports |
| GET | /api/exports/citations | Yes | admin | Export citations |
| GET | /api/exports/users | Yes | admin | Export users |
| GET | /api/exports/vehicles | Yes | admin | Export vehicles |
| GET | /api/exports/statistics | Yes | admin | Statistics report |

---

## Conclusion

This comprehensive flow map documents all major application flows in the FROGIO system:

1. **Authentication & Security:** JWT-based token system with role-based access control
2. **Core Features:** Reports, citations, infractions, vehicles, panic alerts
3. **Real-time:** Socket.IO for live fleet tracking and notifications
4. **Mobile-first:** Flutter app with offline support and background location tracking
5. **Multi-tenant:** Isolated data per municipality using PostgreSQL schemas
6. **Analytics:** Dashboard, statistics, and data export capabilities

All flows follow RESTful API patterns with clear error handling, validation, and authorization checks at every layer.

