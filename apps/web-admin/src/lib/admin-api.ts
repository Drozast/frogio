/**
 * Centralized fetch wrapper for FROGIO admin pages.
 *
 * - Uses cookies (server) or js-cookie (client) for the access token.
 * - Always sends X-Tenant-ID: santa_juana.
 * - Tolerates BOTH `{data: [...]}` and bare-array responses.
 * - Tolerates BOTH camelCase and snake_case fields when the backend mixes them.
 */

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3110';
const TENANT_ID = process.env.NEXT_PUBLIC_TENANT_ID || 'santa_juana';

// ---------------------------------------------------------------------------
// Token resolution
// ---------------------------------------------------------------------------

const isServer = typeof window === 'undefined';

async function getAccessTokenServer(): Promise<string | undefined> {
  // Dynamic import keeps client bundle clean.
  try {
    const { cookies } = await import('next/headers');
    return cookies().get('accessToken')?.value;
  } catch {
    return undefined;
  }
}

function getAccessTokenClient(): string | undefined {
  if (typeof document === 'undefined') return undefined;
  // Parse document.cookie directly - avoids dynamic require() that breaks ESLint/SSR.
  try {
    const match = document.cookie.match(/(?:^|;\s*)accessToken=([^;]+)/);
    if (match) return decodeURIComponent(match[1]);
  } catch {
    // js-cookie may not be installed yet; fall back to manual parse.
  }
  const match = document.cookie.match(/(?:^|;\s*)accessToken=([^;]+)/);
  return match?.[1];
}

async function getToken(explicit?: string): Promise<string | undefined> {
  if (explicit) return explicit;
  return isServer ? getAccessTokenServer() : getAccessTokenClient();
}

// ---------------------------------------------------------------------------
// Core request
// ---------------------------------------------------------------------------

export interface AdminFetchOptions extends Omit<RequestInit, 'headers'> {
  token?: string;
  query?: Record<string, string | number | boolean | undefined | null>;
  headers?: Record<string, string>;
}

function buildQuery(
  q?: AdminFetchOptions['query']
): string {
  if (!q) return '';
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries(q)) {
    if (v === undefined || v === null || v === '') continue;
    params.set(k, String(v));
  }
  const s = params.toString();
  return s ? `?${s}` : '';
}

export async function adminFetch<T = unknown>(
  endpoint: string,
  options: AdminFetchOptions = {}
): Promise<T> {
  const { token, query, headers: extraHeaders, ...rest } = options;
  const auth = await getToken(token);

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'X-Tenant-ID': TENANT_ID,
    ...(extraHeaders ?? {}),
  };
  if (auth) headers['Authorization'] = `Bearer ${auth}`;

  const url = `${API_BASE}${endpoint}${buildQuery(query)}`;

  const res = await fetch(url, {
    ...rest,
    headers,
    cache: rest.cache ?? 'no-store',
  });

  if (!res.ok) {
    let detail: string = `HTTP ${res.status}`;
    try {
      const body = await res.json();
      detail = body?.error || body?.message || JSON.stringify(body);
    } catch {
      // ignore
    }
    // eslint-disable-next-line no-console
    console.error(`[admin-api] ${endpoint} failed:`, detail);
    throw new Error(detail);
  }

  // Handle 204 No Content
  if (res.status === 204) return undefined as unknown as T;

  return (await res.json()) as T;
}

// ---------------------------------------------------------------------------
// Response helpers
// ---------------------------------------------------------------------------

/** Accept both `{data: [...]}` and bare-array responses. */
function unwrapList<T = Record<string, unknown>>(raw: unknown): T[] {
  if (Array.isArray(raw)) return raw as T[];
  if (raw && typeof raw === 'object') {
    const r = raw as Record<string, unknown>;
    if (Array.isArray(r.data)) return r.data as T[];
    if (Array.isArray(r.items)) return r.items as T[];
    if (Array.isArray(r.results)) return r.results as T[];
  }
  // eslint-disable-next-line no-console
  console.warn('[admin-api] expected list response, got:', raw);
  return [];
}

/** Accept both `{data: {...}}` and bare-object responses. */
function unwrapObject<T = Record<string, unknown>>(raw: unknown): T {
  if (raw && typeof raw === 'object') {
    const r = raw as Record<string, unknown>;
    if ('data' in r && r.data && typeof r.data === 'object' && !Array.isArray(r.data)) {
      return r.data as T;
    }
  }
  return raw as T;
}

/**
 * Look up a value tolerating BOTH camelCase and snake_case keys.
 * Walks variants like ('createdAt' | 'created_at').
 */
export function pick<T = unknown>(
  obj: Record<string, unknown> | null | undefined,
  ...keys: string[]
): T | undefined {
  if (!obj) return undefined;
  for (const key of keys) {
    if (obj[key] !== undefined && obj[key] !== null) return obj[key] as T;
    const snake = key.replace(/[A-Z]/g, (m) => `_${m.toLowerCase()}`);
    if (snake !== key && obj[snake] !== undefined && obj[snake] !== null) {
      return obj[snake] as T;
    }
    const camel = key.replace(/_([a-z])/g, (_, c: string) => c.toUpperCase());
    if (camel !== key && obj[camel] !== undefined && obj[camel] !== null) {
      return obj[camel] as T;
    }
  }
  return undefined;
}

function toIsoDate(d?: Date): string | undefined {
  if (!d) return undefined;
  return d.toISOString();
}

// ---------------------------------------------------------------------------
// Typed helpers
// ---------------------------------------------------------------------------

export interface DateRangeFilter {
  from?: Date;
  to?: Date;
  status?: string;
}

export type AdminRecord = Record<string, unknown>;

export async function getCitations(
  params: DateRangeFilter = {}
): Promise<AdminRecord[]> {
  try {
    const raw = await adminFetch('/api/citations', {
      query: {
        from: toIsoDate(params.from),
        to: toIsoDate(params.to),
        status: params.status,
      },
    });
    return unwrapList(raw);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[admin-api] getCitations error', err);
    return [];
  }
}

export async function getReports(
  params: DateRangeFilter = {}
): Promise<AdminRecord[]> {
  try {
    const raw = await adminFetch('/api/reports', {
      query: {
        from: toIsoDate(params.from),
        to: toIsoDate(params.to),
        status: params.status,
      },
    });
    return unwrapList(raw);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[admin-api] getReports error', err);
    return [];
  }
}

export async function getPanicAlerts(): Promise<AdminRecord[]> {
  try {
    const raw = await adminFetch('/api/panic/');
    return unwrapList(raw);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[admin-api] getPanicAlerts error', err);
    return [];
  }
}

export async function getVehicles(): Promise<AdminRecord[]> {
  try {
    const raw = await adminFetch('/api/vehicles');
    return unwrapList(raw);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[admin-api] getVehicles error', err);
    return [];
  }
}

export async function getVehicleLogs(): Promise<AdminRecord[]> {
  try {
    const raw = await adminFetch('/api/vehicles/logs');
    return unwrapList(raw);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[admin-api] getVehicleLogs error', err);
    return [];
  }
}

export interface VehicleLogDetail extends AdminRecord {
  route_points?: AdminRecord[];
  routePoints?: AdminRecord[];
}

export async function getVehicleLog(
  logId: string
): Promise<VehicleLogDetail | null> {
  try {
    const raw = await adminFetch<unknown>(`/api/vehicles/logs/${logId}`);
    const obj = unwrapObject<VehicleLogDetail>(raw);
    // Try to fetch the route from the GPS module if not present.
    if (!obj.route_points && !obj.routePoints) {
      try {
        const route = await adminFetch<unknown>(`/api/gps/log/${logId}/route`);
        const routeArr = unwrapList<AdminRecord>(route);
        obj.route_points = routeArr;
      } catch {
        obj.route_points = [];
      }
    }
    return obj;
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[admin-api] getVehicleLog error', err);
    return null;
  }
}

export interface UsersFilter {
  role?: string;
  active?: boolean;
}

export async function getUsers(
  params: UsersFilter = {}
): Promise<AdminRecord[]> {
  try {
    const raw = await adminFetch('/api/users', {
      query: {
        role: params.role,
        active: params.active,
      },
    });
    return unwrapList(raw);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[admin-api] getUsers error', err);
    return [];
  }
}

export async function getDashboardStats(): Promise<AdminRecord> {
  try {
    const raw = await adminFetch<unknown>('/api/dashboard/stats');
    return unwrapObject<AdminRecord>(raw);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[admin-api] getDashboardStats error', err);
    return {};
  }
}

export async function getLivePositions(): Promise<AdminRecord[]> {
  try {
    const raw = await adminFetch('/api/gps/vehicles/live');
    return unwrapList(raw);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[admin-api] getLivePositions error', err);
    return [];
  }
}

// ---------------------------------------------------------------------------
// Vehicle CRUD
// ---------------------------------------------------------------------------

export interface VehicleInput {
  plate?: string;
  brand?: string;
  model?: string;
  year?: number | string | null;
  type?: string | null;
  color?: string | null;
  status?: string | null;
  is_active?: boolean;
  [k: string]: unknown;
}

export async function createVehicle(body: VehicleInput): Promise<AdminRecord> {
  const raw = await adminFetch<unknown>('/api/vehicles', {
    method: 'POST',
    body: JSON.stringify(body),
  });
  return unwrapObject<AdminRecord>(raw);
}

export async function updateVehicle(
  id: string,
  body: VehicleInput
): Promise<AdminRecord> {
  const raw = await adminFetch<unknown>(`/api/vehicles/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  });
  return unwrapObject<AdminRecord>(raw);
}

export async function deleteVehicle(id: string): Promise<void> {
  await adminFetch<unknown>(`/api/vehicles/${id}`, {
    method: 'DELETE',
  });
}

// ---------------------------------------------------------------------------
// User CRUD (admin)
// ---------------------------------------------------------------------------

export interface CreateUserBody {
  email: string;
  first_name: string;
  last_name: string;
  rut?: string;
  phone?: string;
  role: 'admin' | 'inspector' | 'citizen';
  password: string;
}

export interface UpdateUserBody {
  email?: string;
  first_name?: string;
  last_name?: string;
  rut?: string;
  phone?: string;
  role?: 'admin' | 'inspector' | 'citizen';
  is_active?: boolean;
}

export async function createUser(body: CreateUserBody): Promise<AdminRecord> {
  const raw = await adminFetch<unknown>('/api/users', {
    method: 'POST',
    body: JSON.stringify(body),
  });
  return unwrapObject<AdminRecord>(raw);
}

export async function updateUser(
  id: string,
  body: UpdateUserBody
): Promise<AdminRecord> {
  const raw = await adminFetch<unknown>(`/api/users/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  });
  return unwrapObject<AdminRecord>(raw);
}

export async function toggleUserStatus(id: string): Promise<AdminRecord> {
  const raw = await adminFetch<unknown>(`/api/users/${id}/toggle-status`, {
    method: 'PATCH',
  });
  return unwrapObject<AdminRecord>(raw);
}

export async function updateUserPassword(
  id: string,
  password: string
): Promise<void> {
  await adminFetch<unknown>(`/api/users/${id}/password`, {
    method: 'PATCH',
    body: JSON.stringify({ password }),
  });
}

export async function deleteUser(id: string): Promise<void> {
  await adminFetch<unknown>(`/api/users/${id}`, {
    method: 'DELETE',
  });
}

/**
 * Decode the current user info from the access token JWT (no signature verify).
 * Server-only — uses next/headers cookies().
 */
export async function getCurrentUserFromToken(): Promise<{
  userId: string;
  email?: string;
  role?: string;
} | null> {
  const token = await getAccessTokenServer();
  if (!token) return null;
  return decodeJwtPayload(token);
}

function decodeJwtPayload(token: string): {
  userId: string;
  email?: string;
  role?: string;
} | null {
  try {
    const parts = token.split('.');
    if (parts.length < 2) return null;
    let payloadB64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    while (payloadB64.length % 4 !== 0) payloadB64 += '=';
    const json =
      typeof atob === 'function'
        ? atob(payloadB64)
        : Buffer.from(payloadB64, 'base64').toString('utf8');
    const payload = JSON.parse(json) as Record<string, unknown>;
    const userId =
      (payload.userId as string) ||
      (payload.user_id as string) ||
      (payload.sub as string) ||
      (payload.id as string);
    if (!userId) return null;
    return {
      userId,
      email: payload.email as string | undefined,
      role: payload.role as string | undefined,
    };
  } catch {
    return null;
  }
}

export const adminApi = {
  fetch: adminFetch,
  getCitations,
  getReports,
  getPanicAlerts,
  getVehicles,
  getVehicleLogs,
  getVehicleLog,
  getUsers,
  getDashboardStats,
  getLivePositions,
  createVehicle,
  updateVehicle,
  deleteVehicle,
  createUser,
  updateUser,
  toggleUserStatus,
  updateUserPassword,
  deleteUser,
  getCurrentUserFromToken,
  pick,
};
