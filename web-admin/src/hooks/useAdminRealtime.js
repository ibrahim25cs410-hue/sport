import { useEffect, useRef, useState } from 'react';
import { API_BASE, api, getSession } from '../lib/api';

export function useAdminRealtime(onEvent, enabled = true) {
  const callback = useRef(onEvent);
  const [status, setStatus] = useState('connecting');
  useEffect(() => { callback.current = onEvent; }, [onEvent]);

  useEffect(() => {
    const token = enabled ? getSession()?.token : null;
    if (!token || typeof EventSource === 'undefined') {
      setStatus('offline');
      return undefined;
    }
    let source;
    let active = true;
    let retryTimer;
    let retryDelay = 1000;

    const connect = async () => {
      if (!active) return;
      try {
        const data = await api.realtimeToken();
        if (!active) return;
        source = new EventSource(`${API_BASE}/admin/realtime/events?token=${encodeURIComponent(data.token)}`);
        source.onopen = () => {
          retryDelay = 1000;
          setStatus('online');
        };
        source.onmessage = (event) => {
          try { callback.current?.(JSON.parse(event.data)); } catch { /* ignore malformed events */ }
        };
        source.onerror = () => {
          source?.close();
          if (!active) return;
          setStatus('reconnecting');
          retryTimer = window.setTimeout(connect, retryDelay);
          retryDelay = Math.min(retryDelay * 2, 30000);
        };
      } catch {
        if (!active) return;
        setStatus('reconnecting');
        retryTimer = window.setTimeout(connect, retryDelay);
        retryDelay = Math.min(retryDelay * 2, 30000);
      }
    };

    connect();
    return () => {
      active = false;
      window.clearTimeout(retryTimer);
      source?.close();
    };
  }, [enabled]);

  return status;
}
