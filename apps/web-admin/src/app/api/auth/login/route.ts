import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { API_URL } from '@/lib/api-config';

const TENANT_ID = process.env.NEXT_PUBLIC_TENANT_ID || 'santa_juana';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    console.log('📨 Login request received:', { body, API_URL, TENANT_ID });

    const bodyString = JSON.stringify(body);
    console.log('📤 Sending to backend:', bodyString);

    const response = await fetch(`${API_URL}/api/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Tenant-ID': TENANT_ID,
      },
      body: bodyString,
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(error, { status: response.status });
    }

    const data = await response.json();

    // accessToken non-httpOnly so the client admin-api can attach it as
    // a Bearer header. refreshToken stays httpOnly. JWT lifetime is 15min.
    const isProd = process.env.NODE_ENV === 'production';
    const cookieStore = await cookies();
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

    return NextResponse.json({ success: true, user: data.user });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message || 'Error al iniciar sesión' },
      { status: 500 }
    );
  }
}
