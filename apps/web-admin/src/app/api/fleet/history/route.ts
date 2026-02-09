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
    const vehicleId = searchParams.get('vehicleId');
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');

    if (!vehicleId) {
      return NextResponse.json({ error: 'Se requiere vehicleId' }, { status: 400 });
    }

    let url = `${API_URL}/api/gps/vehicle/${vehicleId}/history`;
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
      return NextResponse.json({ error: error.error || 'Error al obtener historial' }, { status: response.status });
    }

    const data = await response.json();

    // Backend returns array of routes, we need to merge them for the day
    // Each route has: vehicleLogId, vehicleId, points[], totalKm, avgSpeed, maxSpeed, startTime, endTime
    // Frontend expects: points[], totalDistance, avgSpeed, maxSpeed, startTime, endTime

    if (Array.isArray(data) && data.length > 0) {
      // Merge all routes for the day
      const allPoints = data.flatMap((route: Record<string, unknown>) =>
        Array.isArray(route.points) ? route.points : []
      );

      // Sort by recorded_at
      allPoints.sort((a: Record<string, unknown>, b: Record<string, unknown>) => {
        const dateA = new Date(a.recordedAt as string || a.recorded_at as string || 0).getTime();
        const dateB = new Date(b.recordedAt as string || b.recorded_at as string || 0).getTime();
        return dateA - dateB;
      });

      // Sum statistics
      const totalDistance = data.reduce((sum: number, r: Record<string, unknown>) =>
        sum + (Number(r.totalKm) || Number(r.totalDistance) || 0), 0);
      const avgSpeed = data.reduce((sum: number, r: Record<string, unknown>) =>
        sum + (Number(r.avgSpeed) || 0), 0) / data.length || 0;
      const maxSpeed = Math.max(...data.map((r: Record<string, unknown>) =>
        Number(r.maxSpeed) || 0));

      // Get time range
      const startTime = data[data.length - 1]?.startTime || null;
      const endTime = data[0]?.endTime || null;

      return NextResponse.json({
        points: allPoints.map((p: Record<string, unknown>) => ({
          latitude: p.latitude,
          longitude: p.longitude,
          speed: p.speed,
          recorded_at: p.recordedAt || p.recorded_at,
        })),
        totalDistance,
        avgSpeed,
        maxSpeed,
        startTime,
        endTime,
      });
    }

    // Return empty data if no routes found
    return NextResponse.json({
      points: [],
      totalDistance: 0,
      avgSpeed: 0,
      maxSpeed: 0,
      startTime: null,
      endTime: null,
    });
  } catch (error) {
    console.error('Error fetching history:', error);
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 });
  }
}
