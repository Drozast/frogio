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
    const { status } = body;

    if (!status) {
      return NextResponse.json(
        { error: 'El estado es requerido' },
        { status: 400 }
      );
    }

    const validStatuses = ['pendiente', 'en_proceso', 'resuelto', 'rechazado', 'archivado'];
    if (!validStatuses.includes(status)) {
      return NextResponse.json(
        { error: 'Estado inválido' },
        { status: 400 }
      );
    }

    const response = await fetch(`${API_URL}/api/reports/${params.id}`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'X-Tenant-ID': 'santa_juana',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ status }),
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(error, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error updating report status:', error);
    return NextResponse.json(
      { error: 'Error al actualizar el estado del reporte' },
      { status: 500 }
    );
  }
}
