import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';

import { API_URL } from '@/lib/api-config';

export async function GET(request: NextRequest) {
  try {
    const cookieStore = await cookies();
    const accessToken = cookieStore.get('accessToken')?.value;

    if (!accessToken) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const vehicleId = searchParams.get('vehicleId');
    const year = searchParams.get('year');
    const month = searchParams.get('month');

    if (!vehicleId) {
      return NextResponse.json({ error: 'Se requiere vehicleId' }, { status: 400 });
    }

    const params = new URLSearchParams();
    if (year) params.append('year', year);
    if (month) params.append('month', month);

    const url = `${API_URL}/api/gps/vehicle/${vehicleId}/activity-days?${params.toString()}`;

    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(
        { error: error.error || 'Error al obtener días con actividad' },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching activity days:', error);
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 });
  }
}
