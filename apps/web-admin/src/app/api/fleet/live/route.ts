import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';

// Use internal API_URL for server-side requests (container name)
import { API_URL } from '@/lib/api-config';

export async function GET(request: NextRequest) {
  try {
    const cookieStore = await cookies();
    const accessToken = cookieStore.get('accessToken')?.value;

    if (!accessToken) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 401 });
    }

    const response = await fetch(`${API_URL}/api/gps/vehicles/live`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json({ error: error.error || 'Error al obtener posiciones' }, { status: response.status });
    }

    const data = await response.json();

    // Map backend field names to frontend expected names
    const mappedData = Array.isArray(data) ? data.map((item: Record<string, unknown>) => ({
      ...item,
      recordedAt: item.lastUpdate || item.recordedAt || new Date().toISOString(),
    })) : data;

    return NextResponse.json(mappedData);
  } catch (error) {
    console.error('Error fetching live positions:', error);
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 });
  }
}
