'use client';

import { TENANTS, DEFAULT_TENANT } from '@/config/tenants';

/**
 * Returns the API URL for the current tenant, determined from the URL path.
 * Use this instead of process.env.NEXT_PUBLIC_API_URL in client components.
 */
export function getApiUrl(): string {
  if (typeof window === 'undefined') return '';
  const tenantId = window.location.pathname.split('/')[1] || DEFAULT_TENANT;
  return TENANTS[tenantId]?.apiUrl || TENANTS[DEFAULT_TENANT].apiUrl;
}
