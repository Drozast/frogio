import { TENANTS, DEFAULT_TENANT } from '@/config/tenants';

/**
 * Get the API URL for a specific tenant.
 * For server-side API routes, pass the tenantId explicitly.
 * For client components, omit tenantId to auto-detect from URL.
 */
export function getApiUrl(tenantId?: string): string {
  const id = tenantId || DEFAULT_TENANT;
  return TENANTS[id]?.apiUrl || TENANTS[DEFAULT_TENANT].apiUrl;
}

/** @deprecated Use getApiUrl(tenantId) instead */
export const API_URL = getApiUrl();

/** @deprecated Use getApiUrl() instead */
export const CLIENT_API_URL = getApiUrl();
