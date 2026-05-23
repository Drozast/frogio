import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { getTenantConfig, DEFAULT_TENANT } from '@/config/tenants';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const tenantId = body.tenantId || DEFAULT_TENANT;
    const tenant = getTenantConfig(tenantId);

    // Remove tenantId from body before forwarding to backend
    const { tenantId: _tid, ...loginBody } = body;

    const response = await fetch(`${tenant.apiUrl}/api/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Tenant-ID': tenant.id,
      },
      body: JSON.stringify(loginBody),
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(error, { status: response.status });
    }

    const data = await response.json();

    const isProd = process.env.NODE_ENV === 'production';
    const cookieStore = await cookies();

    // Auth cookies
    cookieStore.set('accessToken', data.accessToken, {
      httpOnly: false,
      secure: isProd,
      sameSite: 'lax',
      maxAge: 60 * 15, // 15 minutes
      path: '/',
    });

    cookieStore.set('refreshToken', data.refreshToken, {
      httpOnly: true,
      secure: isProd,
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7, // 7 days
      path: '/',
    });

    // Tenant cookie (client-readable)
    cookieStore.set('tenantId', tenant.id, {
      httpOnly: false,
      secure: isProd,
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7, // 7 days
      path: '/',
    });

    return NextResponse.json({ success: true, user: data.user });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message || 'Error al iniciar sesión' },
      { status: 500 }
    );
  }
}
