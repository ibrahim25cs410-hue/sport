/**
 * React Query hooks — بديل useEffect + load() في UserHome.jsx
 * Optimistic UI + Fast Mode caching
 */
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { riyadaRepository } from '../repositories/riyadaRepository';
import { queryKeys } from '../lib/queryKeys';
import { useAuth } from '../context/AuthContext';
import { useSmartToast } from '../context/SmartToastContext';

export function useUserStats() {
  const { session } = useAuth();
  const userId = session?.user?.id;
  return useQuery({
    queryKey: ['userStats', userId],
    queryFn: () => riyadaRepository.getUserStats(userId),
    enabled: !!userId,
  });
}

export function useBookingHistory() {
  const { session } = useAuth();
  const userId = session?.user?.id;
  return useQuery({
    queryKey: queryKeys.bookingHistory(userId),
    queryFn: () => riyadaRepository.getBookingHistory(userId),
    enabled: !!userId,
    placeholderData: (prev) => prev,
  });
}

export function useReviewEligibility(fieldId) {
  return useQuery({
    queryKey: ['reviewEligibility', fieldId],
    queryFn: () => riyadaRepository.getReviewEligibility(fieldId),
    enabled: !!fieldId,
  });
}

export function useFields() {
  return useQuery({
    queryKey: queryKeys.fields,
    queryFn: () => riyadaRepository.getFields(),
    placeholderData: (prev) => prev,
  });
}

export function useUserBookings() {
  const { session } = useAuth();
  const userId = session?.user?.id;
  return useQuery({
    queryKey: queryKeys.bookings(userId),
    queryFn: () => riyadaRepository.getUserBookings(userId),
    enabled: !!userId,
    placeholderData: (prev) => prev,
  });
}

export function useNotifications() {
  const { session } = useAuth();
  const userId = session?.user?.id;
  return useQuery({
    queryKey: queryKeys.notifications(userId),
    queryFn: () => riyadaRepository.getNotifications(userId),
    enabled: !!userId,
    refetchInterval: 45_000,
    placeholderData: (prev) => prev,
  });
}

export function useCancelBooking() {
  const qc = useQueryClient();
  const { session } = useAuth();
  const userId = session?.user?.id;
  const toast = useSmartToast();

  return useMutation({
    mutationFn: (bookingId) => riyadaRepository.cancelBooking(bookingId),
    onMutate: async (bookingId) => {
      await qc.cancelQueries({ queryKey: queryKeys.bookings(userId) });
      const prev = qc.getQueryData(queryKeys.bookings(userId));
      qc.setQueryData(queryKeys.bookings(userId), (old) =>
        old?.map((b) => (b.id === bookingId ? { ...b, status: 'cancelled', canCancel: false } : b))
      );
      toast.optimistic('جاري إلغاء الحجز…');
      return { prev };
    },
    onError: (err, _id, ctx) => {
      if (ctx?.prev) qc.setQueryData(queryKeys.bookings(userId), ctx.prev);
      toast.smartError(err);
    },
    onSuccess: () => {
      toast.success('تم إلغاء الحجز');
    },
    onSettled: () => {
      qc.invalidateQueries({ queryKey: queryKeys.bookings(userId) });
      riyadaRepository.invalidateBookings();
    },
  });
}

export function useMarkNotificationsRead() {
  const qc = useQueryClient();
  const { session } = useAuth();
  const userId = session?.user?.id;

  return useMutation({
    mutationFn: async ({ id, all }) => {
      if (all) return riyadaRepository.markAllNotificationsRead(userId);
      return riyadaRepository.markNotificationRead(id);
    },
    onSettled: () => {
      qc.invalidateQueries({ queryKey: queryKeys.notifications(userId) });
    },
  });
}

export function useOwnerDashboard() {
  const { session } = useAuth();
  const ownerId = session?.user?.id;
  return useQuery({
    queryKey: queryKeys.ownerDashboard(ownerId),
    queryFn: () => riyadaRepository.getOwnerDashboard(ownerId),
    enabled: !!ownerId,
    placeholderData: (prev) => prev,
  });
}

export function useSchedule(fieldId) {
  return useQuery({
    queryKey: queryKeys.schedule(fieldId),
    queryFn: () => riyadaRepository.getSchedule(fieldId),
    enabled: !!fieldId,
    placeholderData: (prev) => prev,
  });
}

export function useOwnerBookingAction() {
  const qc = useQueryClient();
  const { session } = useAuth();
  const ownerId = session?.user?.id;
  const toast = useSmartToast();

  return useMutation({
    mutationFn: async ({ bookingId, action }) => {
      if (action === 'approve') return riyadaRepository.approveBooking(bookingId);
      return riyadaRepository.rejectBooking(bookingId);
    },
    onMutate: async ({ bookingId, action }) => {
      await qc.cancelQueries({ queryKey: queryKeys.ownerDashboard(ownerId) });
      const prev = qc.getQueryData(queryKeys.ownerDashboard(ownerId));
      const status = action === 'approve' ? 'approved' : 'rejected';
      qc.setQueryData(queryKeys.ownerDashboard(ownerId), (old) => {
        if (!old) return old;
        return {
          ...old,
          pendingCount: Math.max(0, (old.pendingCount ?? 0) - 1),
          bookings: old.bookings?.map((b) => (b.id === bookingId ? { ...b, status } : b)),
        };
      });
      toast.optimistic(action === 'approve' ? 'جاري الموافقة…' : 'جاري الرفض…');
      return { prev };
    },
    onError: (err, _vars, ctx) => {
      if (ctx?.prev) qc.setQueryData(queryKeys.ownerDashboard(ownerId), ctx.prev);
      toast.smartError(err);
    },
    onSuccess: (_data, { action }) => {
      toast.success(action === 'approve' ? 'تمت الموافقة على الحجز' : 'تم رفض الحجز');
    },
    onSettled: () => {
      qc.invalidateQueries({ queryKey: queryKeys.ownerDashboard(ownerId) });
      riyadaRepository.invalidateBookings();
    },
  });
}

export function useUserHomeData() {
  const fields = useFields();
  const bookings = useUserBookings();
  const notifications = useNotifications();

  const isLoading = fields.isLoading && !fields.data;
  const isRefetching = fields.isFetching || bookings.isFetching || notifications.isFetching;
  const error = fields.error || bookings.error || notifications.error;

  return {
    fields: fields.data ?? [],
    bookings: bookings.data ?? [],
    notifications: notifications.data ?? [],
    isLoading,
    isRefetching,
    error,
    refetch: () => {
      fields.refetch();
      bookings.refetch();
      notifications.refetch();
    },
  };
}
