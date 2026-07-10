import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { storage } from '../api';
import { queryKeys } from '../lib/queryKeys';
import { showBrowserNotification } from '../lib/webNotifications';
import { acquireSocket, releaseSocket, joinField, leaveField } from '../lib/socketClient';

/**
 * Shared Socket.io connection for notifications, booking updates, and slot sync.
 * Polling fallback remains in useLiveUpdates when the socket is unavailable.
 */
export function useSocket(enabled = true) {
  const qc = useQueryClient();

  useEffect(() => {
    if (!enabled) return undefined;
    const session = storage.getSession();
    if (!session?.token || !session?.user?.id) return undefined;

    const userId = session.user.id;
    const socket = acquireSocket();
    if (!socket) return undefined;

    const invalidateUser = () => {
      qc.invalidateQueries({ queryKey: queryKeys.notifications(userId) });
      qc.invalidateQueries({ queryKey: queryKeys.bookings(userId) });
    };

    const onNotification = () => invalidateUser();
    const onBookingUpdated = (event) => {
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
    };
    const onSlotSelection = () => {
      qc.invalidateQueries({ queryKey: queryKeys.fields });
      qc.invalidateQueries({ queryKey: ['schedule'] });
    };
    const onSlotRelease = () => {
      qc.invalidateQueries({ queryKey: queryKeys.fields });
      qc.invalidateQueries({ queryKey: ['schedule'] });
    };

    socket.on('notification', onNotification);
    socket.on('bookingUpdated', onBookingUpdated);
    socket.on('slotSelection', onSlotSelection);
    socket.on('slotRelease', onSlotRelease);

    return () => {
      socket.off('notification', onNotification);
      socket.off('bookingUpdated', onBookingUpdated);
      socket.off('slotSelection', onSlotSelection);
      socket.off('slotRelease', onSlotRelease);
      releaseSocket();
    };
  }, [enabled, qc]);

  return { joinField, leaveField };
}
