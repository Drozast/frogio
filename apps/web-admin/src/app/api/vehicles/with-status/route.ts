import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';

import { API_URL } from '@/lib/api-config';

export interface VehicleWithStatus {
  id: string;
  plate: string;
  brand: string | null;
  model: string | null;
  year: number | null;
  color: string | null;
  vehicleType: string | null;
  vehicleStatus: string;
  isActive: boolean;
  // Usage status
  usageStatus: 'available' | 'in_use';
  currentDriverId?: string;
  currentDriverName?: string;
  usageStartTime?: string;
  usagePurpose?: string;
  vehicleLogId?: string;
}

export async function GET() {
  const cookieStore = await cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    return NextResponse.json({ error: 'No autorizado' }, { status: 401 });
  }

  try {
    // Fetch all vehicles and active logs in parallel
    const [vehiclesResponse, activeLogsResponse] = await Promise.all([
      fetch(`${API_URL}/api/vehicles`, {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'X-Tenant-ID': 'santa_juana',
        },
        cache: 'no-store',
      }),
      fetch(`${API_URL}/api/vehicles/logs/active`, {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'X-Tenant-ID': 'santa_juana',
        },
        cache: 'no-store',
      }),
    ]);

    if (!vehiclesResponse.ok) {
      const error = await vehiclesResponse.json();
      return NextResponse.json(error, { status: vehiclesResponse.status });
    }

    const vehicles = await vehiclesResponse.json();

    // Active logs might fail if there are none or permission issues
    let activeLogs: Record<string, unknown>[] = [];
    if (activeLogsResponse.ok) {
      activeLogs = await activeLogsResponse.json();
    }

    // Create a map of vehicle_id -> active log
    const activeLogsByVehicle = new Map<string, Record<string, unknown>>();
    for (const log of activeLogs) {
      const vehicleId = String(log.vehicle_id || log.vehicleId);
      activeLogsByVehicle.set(vehicleId, log);
    }

    // Merge vehicles with their usage status
    const vehiclesWithStatus: VehicleWithStatus[] = vehicles.map((vehicle: Record<string, unknown>) => {
      const vehicleId = String(vehicle.id);
      const activeLog = activeLogsByVehicle.get(vehicleId);

      return {
        id: vehicleId,
        plate: vehicle.plate || '',
        brand: vehicle.brand || null,
        model: vehicle.model || null,
        year: vehicle.year || null,
        color: vehicle.color || null,
        vehicleType: vehicle.vehicle_type || vehicle.vehicleType || null,
        vehicleStatus: vehicle.vehicle_status || vehicle.vehicleStatus || 'activo',
        isActive: vehicle.is_active !== false,
        // Usage status
        usageStatus: activeLog ? 'in_use' : 'available',
        currentDriverId: activeLog ? String(activeLog.driver_id || activeLog.driverId || '') : undefined,
        currentDriverName: activeLog
          ? String(activeLog.driver_name || activeLog.driverName ||
              `${activeLog.driver_first_name || ''} ${activeLog.driver_last_name || ''}`.trim())
          : undefined,
        usageStartTime: activeLog ? String(activeLog.start_time || activeLog.startTime || '') : undefined,
        usagePurpose: activeLog ? String(activeLog.purpose || '') : undefined,
        vehicleLogId: activeLog ? String(activeLog.id) : undefined,
      };
    });

    // Sort: in_use first, then by plate
    vehiclesWithStatus.sort((a, b) => {
      if (a.usageStatus !== b.usageStatus) {
        return a.usageStatus === 'in_use' ? -1 : 1;
      }
      return a.plate.localeCompare(b.plate);
    });

    return NextResponse.json(vehiclesWithStatus);
  } catch (error) {
    console.error('Error fetching vehicles with status:', error);
    return NextResponse.json({ error: 'Error al obtener vehículos' }, { status: 500 });
  }
}
