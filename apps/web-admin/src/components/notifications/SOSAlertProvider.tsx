'use client';

import { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react';
import { io, Socket } from 'socket.io-client';
import SOSAlertModal from './SOSAlertModal';
import SOSAlertToast from './SOSAlertToast';
import { TENANTS, DEFAULT_TENANT } from '@/config/tenants';

interface PanicAlert {
  id: string;
  userId: string;
  userName: string;
  latitude: number;
  longitude: number;
  address?: string;
  message?: string;
  contactPhone?: string;
  createdAt: string;
}

interface SOSAlertContextType {
  activeAlerts: PanicAlert[];
  dismissAlert: (id: string) => void;
}

const SOSAlertContext = createContext<SOSAlertContextType>({
  activeAlerts: [],
  dismissAlert: () => {},
});

export const useSOSAlerts = () => useContext(SOSAlertContext);

function getApiBaseUrl(): string {
  if (typeof window === 'undefined') return '';
  const tenantId = window.location.pathname.split('/')[1] || DEFAULT_TENANT;
  return TENANTS[tenantId]?.apiUrl || TENANTS[DEFAULT_TENANT].apiUrl;
}

function decodeJwtRole(token: string): string | null {
  try {
    const parts = token.split('.');
    if (parts.length < 2) return null;
    let payloadB64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    while (payloadB64.length % 4 !== 0) payloadB64 += '=';
    const payload = JSON.parse(atob(payloadB64)) as Record<string, unknown>;
    return (payload.role as string) || null;
  } catch {
    return null;
  }
}

export default function SOSAlertProvider({ children }: { children: React.ReactNode }) {
  const [, setSocket] = useState<Socket | null>(null);
  const [activeAlerts, setActiveAlerts] = useState<PanicAlert[]>([]);
  const [currentAlert, setCurrentAlert] = useState<PanicAlert | null>(null);
  const [role, setRole] = useState<string | null>(null);
  const [dismissedIds, setDismissedIds] = useState<Set<string>>(new Set());
  const seenAlertIdsRef = useRef<Set<string>>(new Set());

  // Decode role once on mount
  useEffect(() => {
    const token = document.cookie
      .split('; ')
      .find(row => row.startsWith('accessToken='))
      ?.split('=')[1];
    if (token) setRole(decodeJwtRole(token));
  }, []);

  const isInspector = role === 'inspector';

  // Fetch active panic alerts on mount
  const fetchActiveAlerts = useCallback(async () => {
    try {
      const token = document.cookie
        .split('; ')
        .find(row => row.startsWith('accessToken='))
        ?.split('=')[1];

      if (!token) return;

      const response = await fetch(`${getApiBaseUrl()}/api/panic/active`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
      });

      if (response.ok) {
        const alerts: PanicAlert[] = await response.json();
        setActiveAlerts(alerts);
        // For inspectors only: show the most recent alert in the blocking modal
        if (isInspector && alerts.length > 0 && !currentAlert) {
          setCurrentAlert(alerts[0]);
        }
      }
    } catch (error) {
      console.error('Error fetching active alerts:', error);
    }
  }, [currentAlert, isInspector]);

  useEffect(() => {
    // Wait until role is known to avoid showing modal flash to admins
    if (role === null) return;

    fetchActiveAlerts();
    const pollInterval = setInterval(fetchActiveAlerts, 3000);

    const token = document.cookie
      .split('; ')
      .find(row => row.startsWith('accessToken='))
      ?.split('=')[1];

    if (token) {
      const newSocket = io(getApiBaseUrl(), {
        auth: { token },
        transports: ['websocket', 'polling'],
      });

      newSocket.on('connect', () => {
        console.log('Socket connected for SOS alerts');
        newSocket.emit('join-room', 'admin-alerts');
      });

      newSocket.on('panic-alert', (alert: PanicAlert) => {
        const isNew = !seenAlertIdsRef.current.has(alert.id);
        seenAlertIdsRef.current.add(alert.id);

        setActiveAlerts(prev => {
          const exists = prev.some(a => a.id === alert.id);
          if (exists) return prev;
          return [alert, ...prev];
        });

        // Inspectors get blocked by the modal; everyone else gets non-blocking toasts.
        if (isInspector) {
          setCurrentAlert(alert);
        }

        if (isNew) {
          playAlertSound();
          showBrowserNotification(alert);
        }
      });

      newSocket.on('panic-alert-resolved', (alertId: string) => {
        setActiveAlerts(prev => prev.filter(a => a.id !== alertId));
        setCurrentAlert(prev => (prev?.id === alertId ? null : prev));
        setDismissedIds(prev => {
          const next = new Set(prev);
          next.delete(alertId);
          return next;
        });
      });

      setSocket(newSocket);

      return () => {
        clearInterval(pollInterval);
        newSocket.disconnect();
      };
    }

    return () => {
      clearInterval(pollInterval);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [role]);

  const playAlertSound = () => {
    try {
      const audio = new Audio('/sounds/alert.mp3');
      audio.volume = 0.7;
      audio.play().catch(() => {
        console.log('Audio blocked by browser');
      });
    } catch {
      console.log('Could not play alert sound');
    }
  };

  const showBrowserNotification = (alert: PanicAlert) => {
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification('🚨 ALERTA DE EMERGENCIA', {
        body: `${alert.userName} necesita ayuda!\nUbicación: ${alert.address || 'Ver en mapa'}`,
        icon: '/icon-192.png',
        tag: `panic-${alert.id}`,
        requireInteraction: true,
      });
    }
  };

  const dismissAlert = useCallback((id: string) => {
    setCurrentAlert(prev => (prev?.id === id ? null : prev));
    setDismissedIds(prev => {
      const next = new Set(prev);
      next.add(id);
      return next;
    });
  }, []);

  // Request notification permission on mount
  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }, []);

  // Visible toasts for non-inspector roles (admins, etc.)
  const toastAlerts = !isInspector
    ? activeAlerts.filter(a => !dismissedIds.has(a.id))
    : [];

  return (
    <SOSAlertContext.Provider value={{ activeAlerts, dismissAlert }}>
      {children}

      {/* Blocking modal: only for inspectors */}
      {isInspector && currentAlert && (
        <SOSAlertModal
          alert={currentAlert}
          onClose={() => dismissAlert(currentAlert.id)}
        />
      )}

      {/* Non-blocking toast stack: for admins and other roles */}
      {toastAlerts.length > 0 && (
        <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-3 max-w-sm w-full pointer-events-none">
          {toastAlerts.slice(0, 3).map(alert => (
            <SOSAlertToast
              key={alert.id}
              alert={alert}
              onDismiss={() => dismissAlert(alert.id)}
            />
          ))}
        </div>
      )}
    </SOSAlertContext.Provider>
  );
}
