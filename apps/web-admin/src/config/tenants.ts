/**
 * Centralized tenant configuration for FROGIO multi-municipality path routing.
 *
 * Each tenant (municipality) has its own API backend (VPS) and optional theme.
 * The web-admin is a single deployment that serves all tenants via path routing:
 *   frogio.cl/[tenant]/...
 */

export interface TenantConfig {
  id: string;           // e.g., 'santa_juana'
  name: string;         // e.g., 'Santa Juana'
  fullName: string;     // e.g., 'Municipalidad de Santa Juana'
  apiUrl: string;       // e.g., 'https://api-frogio.supertools.cl'
  theme?: {
    primary: string;    // CSS HSL values without hsl(), e.g. '126 57% 23%'
  };
}

export const TENANTS: Record<string, TenantConfig> = {
  santa_juana: {
    id: 'santa_juana',
    name: 'Santa Juana',
    fullName: 'Municipalidad de Santa Juana',
    apiUrl: 'https://api-frogio.supertools.cl',
    theme: { primary: '126 57% 23%' },
  },
  nunoa: {
    id: 'nunoa',
    name: 'Ñuñoa',
    fullName: 'Municipalidad de Ñuñoa',
    apiUrl: 'https://api-nunoa.supertools.cl',
    theme: { primary: '220 60% 30%' },
  },
  // Aliases (common misspellings)
  santajuana: {
    id: 'santa_juana',
    name: 'Santa Juana',
    fullName: 'Municipalidad de Santa Juana',
    apiUrl: 'https://api-frogio.supertools.cl',
    theme: { primary: '126 57% 23%' },
  },
};

export const DEFAULT_TENANT = 'santa_juana';

/**
 * Look up a tenant by its ID. Falls back to DEFAULT_TENANT if not found.
 */
export function getTenantConfig(tenantId: string): TenantConfig {
  return TENANTS[tenantId] || TENANTS[DEFAULT_TENANT];
}

/**
 * Extract the tenant from a URL pathname.
 * Returns the tenant ID if the first segment matches a known tenant,
 * otherwise returns the DEFAULT_TENANT.
 */
export function getTenantFromPath(pathname: string): string {
  const match = pathname.match(/^\/([^/]+)/);
  const candidate = match?.[1];
  if (candidate && TENANTS[candidate]) return candidate;
  return DEFAULT_TENANT;
}

/**
 * Check if a pathname already starts with a known tenant prefix.
 */
export function hasTenantPrefix(pathname: string): boolean {
  const match = pathname.match(/^\/([^/]+)/);
  const candidate = match?.[1];
  return !!(candidate && TENANTS[candidate]);
}

/**
 * Strip the tenant prefix from a pathname.
 * "/santa_juana/dashboard" → "/dashboard"
 * "/nunoa/login" → "/login"
 */
export function stripTenantFromPath(pathname: string): string {
  if (!hasTenantPrefix(pathname)) return pathname;
  const match = pathname.match(/^\/([^/]+)(.*)/);
  return match?.[2] || '/';
}
