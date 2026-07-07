/**
 * تحديثات فورية — SignalR + polling احتياطي
 */
import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useAuth } from '../context/AuthContext';
import { queryKeys } from '../lib/queryKeys';
import { useSignalR } from './useSignalR';

const FALLBACK_POLL_MS = 60_000;

export function useLiveUpdates(enabled = true) {
  const qc = useQueryClient();
  const { session } = useAuth();
  const userId = session?.user?.id;

  useSignalR(enabled);

  useEffect(() => {
    if (!enabled || !userId) return undefined;

    const tick = () => {
      qc.invalidateQueries({ queryKey: queryKeys.notifications(userId) });
      qc.invalidateQueries({ queryKey: queryKeys.bookings(userId) });
    };

    const id = setInterval(tick, FALLBACK_POLL_MS);
    return () => clearInterval(id);
  }, [enabled, userId, qc]);
}
