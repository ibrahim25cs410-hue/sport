import { useEffect, useRef } from 'react';
import * as signalR from '@microsoft/signalr';
import { useQueryClient } from '@tanstack/react-query';
import { API_BASE, storage } from '../api';
import { queryKeys } from '../lib/queryKeys';
import { showBrowserNotification } from '../lib/webNotifications';

const HUB_URL = API_BASE.replace(/\/api\/?$/, '') + '/hubs/booking';

/**
 * اتصال SignalR للتحديثات اللحظية — مع fallback للـ polling في useLiveUpdates.
 */
export function useSignalR(enabled = true) {
  const qc = useQueryClient();
  const connectionRef = useRef(null);

  useEffect(() => {
    if (!enabled) return undefined;
    const session = storage.getSession();
    if (!session?.token || !session?.user?.id) return undefined;

    const userId = session.user.id;
    const connection = new signalR.HubConnectionBuilder()
      .withUrl(HUB_URL, { accessTokenFactory: () => session.token })
      .withAutomaticReconnect([0, 2000, 5000, 10000])
      .configureLogging(signalR.LogLevel.Warning)
      .build();

    const invalidateUser = () => {
      qc.invalidateQueries({ queryKey: queryKeys.notifications(userId) });
      qc.invalidateQueries({ queryKey: queryKeys.bookings(userId) });
    };

    connection.on('BookingUpdated', (event) => {
      invalidateUser();
      qc.invalidateQueries({ queryKey: queryKeys.bookingHistory(userId) });
      if (event?.status === 'approved') {
        showBrowserNotification({
          title: 'تم قبول الحجز',
          body: event?.messageArgs?.fieldName
            ? `تمت الموافقة — ${event.messageArgs.fieldName}`
            : 'تمت الموافقة على حجزك',
          tag: `booking-${event?.bookingId ?? 'x'}`,
        });
      }
    });
    connection.on('NotifySlotSelection', () => {
      qc.invalidateQueries({ queryKey: queryKeys.fields });
      qc.invalidateQueries({ queryKey: ['schedule'] });
    });
    connection.on('ReleaseSlot', () => {
      qc.invalidateQueries({ queryKey: queryKeys.fields });
      qc.invalidateQueries({ queryKey: ['schedule'] });
    });

    connection
      .start()
      .catch((err) => console.warn('[SignalR] connect failed — polling fallback', err));

    connectionRef.current = connection;

    return () => {
      connection.stop().catch(() => {});
      connectionRef.current = null;
    };
  }, [enabled, qc]);

  return connectionRef;
}
