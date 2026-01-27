'use client';

import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { io, Socket } from 'socket.io-client';
import SOSAlertModal from './SOSAlertModal';

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

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

export default function SOSAlertProvider({ children }: { children: React.ReactNode }) {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [activeAlerts, setActiveAlerts] = useState<PanicAlert[]>([]);
  const [currentAlert, setCurrentAlert] = useState<PanicAlert | null>(null);

  // Fetch active panic alerts on mount
  const fetchActiveAlerts = useCallback(async () => {
    try {
      const token = document.cookie
        .split('; ')
        .find(row => row.startsWith('accessToken='))
        ?.split('=')[1];

      if (!token) return;

      const response = await fetch(`${API_URL}/api/panic/active`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
      });

      if (response.ok) {
        const alerts = await response.json();
        setActiveAlerts(alerts);
        // Show the most recent active alert
        if (alerts.length > 0 && !currentAlert) {
          setCurrentAlert(alerts[0]);
        }
      }
    } catch (error) {
      console.error('Error fetching active alerts:', error);
    }
  }, [currentAlert]);

  useEffect(() => {
    // Initial fetch
    fetchActiveAlerts();

    // Poll for new alerts every 3 seconds (backup for socket)
    const pollInterval = setInterval(fetchActiveAlerts, 3000);

    // Setup Socket.io connection
    const token = document.cookie
      .split('; ')
      .find(row => row.startsWith('accessToken='))
      ?.split('=')[1];

    if (token) {
      const newSocket = io(API_URL, {
        auth: { token },
        transports: ['websocket', 'polling'],
      });

      newSocket.on('connect', () => {
        console.log('Socket connected for SOS alerts');
        newSocket.emit('join-room', 'admin-alerts');
      });

      newSocket.on('panic-alert', (alert: PanicAlert) => {
        console.log('Received panic alert:', alert);
        setActiveAlerts(prev => {
          const exists = prev.some(a => a.id === alert.id);
          if (exists) return prev;
          return [alert, ...prev];
        });
        setCurrentAlert(alert);

        // Play alert sound
        playAlertSound();

        // Show browser notification
        showBrowserNotification(alert);
      });

      newSocket.on('panic-alert-resolved', (alertId: string) => {
        setActiveAlerts(prev => prev.filter(a => a.id !== alertId));
        if (currentAlert?.id === alertId) {
          setCurrentAlert(null);
        }
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
  }, [fetchActiveAlerts]);

  const playAlertSound = () => {
    try {
      const audio = new Audio('/sounds/alert.mp3');
      audio.volume = 0.7;
      audio.play().catch(() => {
        // Audio might be blocked by browser
        console.log('Audio blocked by browser');
      });
    } catch (e) {
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
    if (currentAlert?.id === id) {
      setCurrentAlert(null);
    }
  }, [currentAlert]);

  // Request notification permission on mount
  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }, []);

  return (
    <SOSAlertContext.Provider value={{ activeAlerts, dismissAlert }}>
      {children}
      {currentAlert && (
        <SOSAlertModal
          alert={currentAlert}
          onClose={() => dismissAlert(currentAlert.id)}
        />
      )}
    </SOSAlertContext.Provider>
  );
}
