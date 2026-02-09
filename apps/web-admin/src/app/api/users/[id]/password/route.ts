import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';

import { API_URL } from '@/lib/api-config';

export async function PATCH(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const cookieStore = await cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    return NextResponse.json({ error: 'No autorizado' }, { status: 401 });
  }

  try {
    const body = await request.json();

    if (!body?.password || typeof body.password !== 'string') {
      return NextResponse.json({ error: 'Contraseña inválida' }, { status: 400 });
    }

    const response = await fetch(`${API_URL}/api/users/${params.id}/password`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'X-Tenant-ID': 'santa_juana',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ password: body.password }),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Error al actualizar contraseña' }));
      return NextResponse.json(error, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error updating password:', error);
    return NextResponse.json(
      { error: 'Error al actualizar contraseña' },
      { status: 500 }
    );
  }
}

