import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getTenantFromPath, hasTenantPrefix, stripTenantFromPath, DEFAULT_TENANT, TENANTS } from '@/config/tenants';

/**
 * Check if a pathname should bypass both auth and tenant routing.
 * Static assets, Next.js internals, and API routes must not be intercepted.
 */
function isStaticOrApi(pathname: string): boolean {
  return (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname.startsWith('/static') ||
    pathname.startsWith('/favicon.ico') ||
    /\.(ico|png|svg|jpe?g|gif|css|js|map|woff2?|ttf|eot)$/i.test(pathname)
  );
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const accessToken = request.cookies.get('accessToken')?.value;

  // ------------------------------------------------------------------
  // Bypass: static assets, Next internals, API routes
  // ------------------------------------------------------------------
  if (isStaticOrApi(pathname)) {
    return NextResponse.next();
  }

  // ------------------------------------------------------------------
  // TENANT DETECTION
  // ------------------------------------------------------------------
  // If the URL has no tenant prefix (e.g., "/login", "/dashboard"),
  // redirect to the tenant-prefixed version.
  // Prefer the existing tenantId cookie so we stay on the same municipality.
  if (!hasTenantPrefix(pathname)) {
    const cookieTenant = request.cookies.get('tenantId')?.value;
    const preferredTenant =
      cookieTenant && TENANTS[cookieTenant] ? cookieTenant : DEFAULT_TENANT;
    const url = request.nextUrl.clone();
    const rest = pathname === '/' ? '/login' : pathname;
    url.pathname = `/${preferredTenant}${rest}`;
    return NextResponse.redirect(url);
  }

  // At this point pathname is e.g. "/santa_juana/login" or "/nunoa/dashboard"
  const tenant = getTenantFromPath(pathname);
  const cleanPath = stripTenantFromPath(pathname); // "/login", "/dashboard", etc.

  // ------------------------------------------------------------------
  // STATIC/ASSETS: after stripping tenant prefix, if the clean path is
  // a Next.js internal or static file, let Next.js serve it directly.
  // Must check BEFORE auth redirect to avoid blocking CSS/JS/fonts.
  // ------------------------------------------------------------------
  if (
    cleanPath.startsWith('/_next') ||
    cleanPath.startsWith('/favicon.ico') ||
    /\.(ico|png|svg|jpe?g|gif|css|js|map|woff2?|ttf|eot)$/i.test(cleanPath)
  ) {
    return NextResponse.rewrite(new URL(cleanPath, request.url));
  }

  // ------------------------------------------------------------------
  // AUTH: if the clean path is /login, allow without auth
  // ------------------------------------------------------------------
  if (cleanPath === '/login' || cleanPath.startsWith('/login')) {
    const response = NextResponse.rewrite(new URL(cleanPath, request.url));
    response.headers.set('x-tenant-id', tenant);
    response.cookies.set('tenantId', tenant, {
      httpOnly: false,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7, // 7 days
      path: '/',
    });
    return response;
  }

  // ------------------------------------------------------------------
  // AUTH: protected route — require access token
  // ------------------------------------------------------------------
  if (!accessToken) {
    const url = request.nextUrl.clone();
    url.pathname = `/${tenant}/login`;
    return NextResponse.redirect(url);
  }

  // ------------------------------------------------------------------
  // Authenticated — rewrite to clean path, set tenant identity
  // ------------------------------------------------------------------
  const response = NextResponse.rewrite(new URL(cleanPath, request.url));
  response.headers.set('x-tenant-id', tenant);
  response.cookies.set('tenantId', tenant, {
    httpOnly: false,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 7,
    path: '/',
  });
  return response;
}

export const config = {
  // Only exclude paths that START with _next/ or favicon.ico
  // Tenant-prefixed paths like /santa_juana/_next/... will still pass through
  matcher: ['/((?!_next/|favicon\\.ico).*)'],
};
