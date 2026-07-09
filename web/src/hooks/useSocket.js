import { useEffect, useRef } from 'react';
import { io } from 'socket.io-client';
import { useQueryClient } from '@tanstack/react-query';
import { API_BASE, storage } from '../api';
import { queryKeys } from '../lib/queryKeys';
import { showBrowserNotification } from '../lib/webNotifications';

const SOCKET_URL = API_BASE.replace(/\/api\/?$/, '');

/**
 * Socket.io connection for live notifications, booking updates, and slot sync.
 * Polling fallback remains in useLiveUpdates when the socket is unavailable.
 */
export function useSocket(enabled = true) {
  const qc = useQueryClient();
  const socketRef = useRef(null);

  useEffect(() => {
    if (!enabled) return undefined;
    const session = storage.getSession();
    if (!session?.token || !session?.user?.id) return undefined;

    const userId = session.user.id;
    const socket = io(SOCKET_URL, {
      auth: { token: session.token },
      transports: ['websocket'],
      reconnection: true,
      reconnectionAttempts: 10,
      reconnectionDelay: 2000,
    });

    const invalidateUser = () => {
      qc.invalidateQueries({ queryKey: queryKeys.notifications(userId) });
      qc.invalidateQueries({ queryKey: queryKeys.bookings(userId) });
    };

    socket.on('notification', () => {
      invalidateUser();
    });

    socket.on('bookingUpdated', (event) => {
      invalidateUser();
      qc.invalidateQueries({ queryKey: queryKeys.bookingHistory(userId) });
      const status = event?.status;
      if (status === 'approved' || status === 'confirmed') {
        showBrowserNotification({
          title: 'تم قبول الحجز',
          body: event?.messageArgs?.fieldName || event?.messageArgs?.stadiumName
            ? `تمت الموافقة — ${event.messageArgs.fieldName || event.messageArgs.stadiumName}`
            : 'تمت الموافقة على حجزك',
          tag: `booking-${event?.bookingId ?? 'x'}`,
        });
      }
    });

    socket.on('slotSelection', () => {
      qc.invalidateQueries({ queryKey: queryKeys.fields });
      qc.invalidateQueries({ queryKey: ['schedule'] });
    });

    socket.on('slotRelease', () => {
      qc.invalidateQueries({ queryKey: queryKeys.fields });
      qc.invalidateQueries({ queryKey: ['schedule'] });
    });

    socket.on('connect_error', (err) => {
      console.warn('[Socket] connect failed — polling fallback', err?.message || err);
    });

    socketRef.current = socket;

    return () => {
      socket.disconnect();
      socketRef.current = null;
    };
  }, [enabled, qc]);

  return socketRef;
}
