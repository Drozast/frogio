import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import AppLayout from '@/components/layout/AppLayout';
import { TENANTS, DEFAULT_TENANT } from '@/config/tenants';

async function getNotifications(token: string, tenantId: string) {
  try {
    const apiUrl = TENANTS[tenantId]?.apiUrl || TENANTS[DEFAULT_TENANT].apiUrl;
    const response = await fetch(`${apiUrl}/api/notifications`, {
      headers: { Authorization: `Bearer ${token}` },
      cache: 'no-store',
    });

    if (!response.ok) return [];
    const result = await response.json();
    return result.data || [];
  } catch (error) {
    console.error('Error fetching notifications:', error);
    return [];
  }
}

export default async function NotificationsPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;
  const tenantId = cookieStore.get('tenantId')?.value || DEFAULT_TENANT;

  if (!accessToken) {
    redirect('/login');
  }

  const notifications = await getNotifications(accessToken, tenantId);
  const unreadCount = notifications.filter((n: any) => !n.is_read).length;

  return (
    <AppLayout>
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-6">Notificaciones</h1>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div className="bg-white shadow rounded-lg p-6">
            <div className="text-sm font-medium text-gray-500">Total Notificaciones</div>
            <div className="text-3xl font-semibold text-gray-900 mt-2">{notifications.length}</div>
          </div>
          <div className="bg-white shadow rounded-lg p-6">
            <div className="text-sm font-medium text-gray-500">Sin Leer</div>
            <div className="text-3xl font-semibold text-indigo-600 mt-2">{unreadCount}</div>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          {notifications.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              No hay notificaciones
            </div>
          ) : (
            <div className="divide-y divide-gray-200">
              {notifications.map((notification: any) => (
                <div
                  key={notification.id}
                  className={`p-6 hover:bg-gray-50 ${!notification.is_read ? 'bg-blue-50' : ''}`}
                >
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <TypeBadge type={notification.type} />
                        {!notification.is_read && (
                          <span className="h-2 w-2 bg-blue-600 rounded-full"></span>
                        )}
                      </div>
                      <h3 className="text-lg font-medium text-gray-900 mt-2">
                        {notification.title}
                      </h3>
                      <p className="text-sm text-gray-600 mt-1">
                        {notification.message}
                      </p>
                      <div className="flex items-center gap-4 mt-3 text-xs text-gray-500">
                        <span>
                          {new Date(notification.created_at).toLocaleString('es-CL')}
                        </span>
                        {notification.is_sent && (
                          <span className="flex items-center gap-1">
                            <span className="text-green-600">✓</span> Enviada
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </AppLayout>
  );
}

function TypeBadge({ type }: { type: string }) {
  const config: Record<string, { color: string; label: string }> = {
    info: { color: 'bg-blue-100 text-blue-800', label: 'Info' },
    warning: { color: 'bg-yellow-100 text-yellow-800', label: 'Advertencia' },
    error: { color: 'bg-red-100 text-red-800', label: 'Error' },
    success: { color: 'bg-green-100 text-green-800', label: 'Éxito' },
    report: { color: 'bg-purple-100 text-purple-800', label: 'Reporte' },
    infraction: { color: 'bg-orange-100 text-orange-800', label: 'Infracción' },
    citation: { color: 'bg-indigo-100 text-indigo-800', label: 'Citación' },
  };

  const { color, label } = config[type] || { color: 'bg-gray-100 text-gray-800', label: type };

  return (
    <span className={`px-2 py-1 text-xs font-semibold rounded ${color}`}>
      {label}
    </span>
  );
}
