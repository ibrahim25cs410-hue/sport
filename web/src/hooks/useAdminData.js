import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { riyadaRepository } from '../repositories/riyadaRepository';
import { useAuth } from '../context/AuthContext';
import { useSmartToast } from '../context/SmartToastContext';

const PAGE = 20;

export function useInfiniteFields() {
  return useInfiniteQuery({
    queryKey: ['fields', 'infinite'],
    queryFn: ({ pageParam = 1 }) => riyadaRepository.getFields(pageParam, PAGE),
    getNextPageParam: (lastPage, _all, lastPageParam) =>
      lastPage.length >= PAGE ? lastPageParam + 1 : undefined,
    initialPageParam: 1,
  });
}

export function useAdminStats() {
  const { session } = useAuth();
  return useQuery({
    queryKey: ['adminStats'],
    queryFn: () => riyadaRepository.getAdminStats(),
    enabled: session?.user?.role === 'admin',
  });
}

export function useAdminFinancials() {
  const { session } = useAuth();
  return useQuery({
    queryKey: ['adminFinancials'],
    queryFn: () => riyadaRepository.getAdminFinancials(),
    enabled: session?.user?.role === 'admin',
  });
}

export function useAdminOwners() {
  const { session } = useAuth();
  return useQuery({
    queryKey: ['adminOwners'],
    queryFn: () => riyadaRepository.getAdminOwners(),
    enabled: session?.user?.role === 'admin',
  });
}

export function useAdminFields() {
  const { session } = useAuth();
  return useQuery({
    queryKey: ['adminFields'],
    queryFn: () => riyadaRepository.getAdminFields(),
    enabled: session?.user?.role === 'admin',
  });
}

export function useAdminPendingBookings() {
  const { session } = useAuth();
  return useQuery({
    queryKey: ['adminPending'],
    queryFn: () => riyadaRepository.getAdminPendingBookings(),
    enabled: session?.user?.role === 'admin',
  });
}

export function useAdminToggleField() {
  const qc = useQueryClient();
  const toast = useSmartToast();
  return useMutation({
    mutationFn: (id) => riyadaRepository.toggleAdminField(id),
    onSuccess: () => {
      toast.success('تم تحديث حالة الملعب');
      qc.invalidateQueries({ queryKey: ['adminFields'] });
      riyadaRepository.invalidateFields();
    },
    onError: (e) => toast.smartError(e),
  });
}

export function useAdminTopUp() {
  const qc = useQueryClient();
  const toast = useSmartToast();
  return useMutation({
    mutationFn: ({ ownerId, amount, note }) => riyadaRepository.adminTopUp(ownerId, amount, note),
    onSuccess: () => {
      toast.success('تم شحن المحفظة');
      qc.invalidateQueries({ queryKey: ['adminOwners'] });
    },
    onError: (e) => toast.smartError(e),
  });
}
