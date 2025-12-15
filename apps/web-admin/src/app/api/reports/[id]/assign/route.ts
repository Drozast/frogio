import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';

const API_URL = process.env.API_URL || 'http://backend:3000';

export async function PATCH(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    return NextResponse.json({ error: 'No autorizado' }, { status: 401 });
  }

  try {
    const body = await request.json();
    const { assigned_to } = body;

    if (!assigned_to) {
      return NextResponse.json(
        { error: 'El ID del inspector es requerido' },
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
      body: JSON.stringify({
        assigned_to,
        status: 'en_proceso' // Automatically update status when assigning
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(error, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error assigning inspector:', error);
    return NextResponse.json(
      { error: 'Error al asignar el inspector' },
      { status: 500 }
    );
  }
}
