import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';

import { API_URL } from '@/lib/api-config';

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
    // First, get the current user to know their current status
    const getUserResponse = await fetch(`${API_URL}/api/users/${params.id}`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'X-Tenant-ID': 'santa_juana',
      },
    });

    if (!getUserResponse.ok) {
      return NextResponse.json(
        { error: 'Usuario no encontrado' },
        { status: 404 }
      );
    }

    const user = await getUserResponse.json();
    const newStatus = !user.is_active;

    // Update the user's active status
    const updateResponse = await fetch(`${API_URL}/api/users/${params.id}`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'X-Tenant-ID': 'santa_juana',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ is_active: newStatus }),
    });

    if (!updateResponse.ok) {
      const error = await updateResponse.json();
      return NextResponse.json(error, { status: updateResponse.status });
    }

    const updatedUser = await updateResponse.json();
    return NextResponse.json(updatedUser);
  } catch (error) {
    console.error('Error toggling user status:', error);
    return NextResponse.json(
      { error: 'Error al cambiar el estado del usuario' },
      { status: 500 }
    );
  }
}
