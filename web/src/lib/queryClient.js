import { QueryClient } from '@tanstack/react-query';

/** إعدادات 365Scores-style: عرض فوري من الكاش + تحديث خلفي */
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      gcTime: 5 * 60_000,
      refetchOnWindowFocus: true,
      refetchOnReconnect: true,
      retry: (count, err) => err?.retryable !== false && count < 2,
    },
    mutations: {
      retry: 0,
    },
  },
});
