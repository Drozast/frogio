'use client';

import { useEffect, useCallback, useRef } from 'react';

interface UseAutoRefreshOptions {
  interval?: number; // milliseconds
  enabled?: boolean;
}

export function useAutoRefresh(
  fetchFn: () => Promise<void>,
  options: UseAutoRefreshOptions = {}
) {
  const { interval = 3000, enabled = true } = options;
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);
  const isVisibleRef = useRef(true);

  const refresh = useCallback(async () => {
    if (!isVisibleRef.current || !enabled) return;
    try {
      await fetchFn();
    } catch (error) {
      console.error('Auto-refresh error:', error);
    }
  }, [fetchFn, enabled]);

  useEffect(() => {
    if (!enabled) return;

    const startRefresh = () => {
      timeoutRef.current = setInterval(refresh, interval);
    };

    const stopRefresh = () => {
      if (timeoutRef.current) {
        clearInterval(timeoutRef.current);
        timeoutRef.current = null;
      }
    };

    const handleVisibilityChange = () => {
      isVisibleRef.current = document.visibilityState === 'visible';
      if (isVisibleRef.current) {
        refresh(); // Refresh immediately when becoming visible
        startRefresh();
      } else {
        stopRefresh();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    startRefresh();

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      stopRefresh();
    };
  }, [refresh, interval, enabled]);

  return { refresh };
}
