import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';

import { API_URL } from '@/lib/api-config';

export async function GET(request: NextRequest) {
  try {
    const cookieStore = cookies();
    const accessToken = cookieStore.get('accessToken')?.value;

    if (!accessToken) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');

    let url = `${API_URL}/api/gps/stats`;
    const params = new URLSearchParams();
    if (startDate) params.append('startDate', startDate);
    if (endDate) params.append('endDate', endDate);
    if (params.toString()) url += `?${params.toString()}`;

    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json({ error: error.error || 'Error al obtener estadísticas' }, { status: response.status });
    }

    const data = await response.json();

    // Map backend response to frontend expected format
    const mappedData = {
      totals: {
        totalDistance: data.totalKm || 0,
        totalTrips: data.totalTrips || 0,
        totalPoints: data.totalPoints || 0,
      },
      byVehicle: (data.byVehicle || []).map((v: Record<string, unknown>) => ({
        vehicleId: v.vehicleId,
        vehiclePlate: v.vehiclePlate || '',
        vehicleBrand: v.vehicleBrand || '',
        vehicleModel: v.vehicleModel || '',
        totalDistanceKm: v.totalKm || v.totalDistanceKm || 0,
        totalTrips: v.totalTrips || 0,
        totalPoints: v.totalPoints || 0,
        avgSpeed: v.avgSpeed || 0,
        maxSpeed: v.maxSpeed || 0,
      })),
      byInspector: (data.byInspector || []).map((i: Record<string, unknown>) => ({
        inspectorId: i.inspectorId,
        inspectorName: i.inspectorName || '',
        totalDistanceKm: i.totalKm || i.totalDistanceKm || 0,
        totalTrips: i.totalTrips || 0,
        vehiclesUsed: i.vehiclesUsed || 1,
      })),
    };

    return NextResponse.json(mappedData);
  } catch (error) {
    console.error('Error fetching stats:', error);
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 });
  }
}
