// Centralized API URL configuration
// Uses internal Docker network URL for SSR, external URL as fallback

export const API_URL =
  process.env.INTERNAL_API_URL ||
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  'http://localhost:3000';

// Client-side API URL (always uses public URL)
export const CLIENT_API_URL =
  process.env.NEXT_PUBLIC_API_URL ||
  'http://localhost:3000';

import { getTenantConfig, DEFAULT_TENANT } from '@/config/tenants';

/**
 * Get the API URL for the current tenant. Used by client components
 * that need to call the external API directly (WebSocket, polling, etc.).
 */
export function getTenantApiUrl(tenantId?: string): string {
  // Try to read tenant from URL path if not provided
  if (!tenantId && typeof window !== 'undefined') {
    const match = window.location.pathname.match(/^\/([^/]+)/);
    tenantId = match?.[1] || DEFAULT_TENANT;
  }
  return getTenantConfig(tenantId || DEFAULT_TENANT).apiUrl;
}
