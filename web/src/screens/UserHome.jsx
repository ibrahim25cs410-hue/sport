import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { MapPin, Phone, Clock, Timer, XCircle, RefreshCw, Building2, Calendar, Bell, Search, Sparkles } from 'lucide-react';
import { formatDateTime, formatRemaining, formatMoney } from '../api';
import { useAuth } from '../context/AuthContext';
import { useSmartToast } from '../context/SmartToastContext';
import { useInfiniteFields } from '../hooks/useAdminData';
import { useUserBookings, useCancelBooking, useMarkNotificationsRead, useNotifications } from '../hooks/useRiyadaData';
import { useLiveUpdates } from '../hooks/useLiveUpdates';
import { requestNotificationPermission } from '../lib/webNotifications';
import Header from '../components/Header';
import BottomNav from '../components/BottomNav';
import StadiumCard from '../components/StadiumCard';
import Badge from '../components/Badge';
import Button from '../components/Button';
import EmptyState from '../components/EmptyState';
import ConfirmDialog from '../components/ConfirmDialog';
import { FieldsListSkeleton } from '../components/Skeleton';
import PageTransition, { StaggerList, StaggerItem } from '../components/PageTransition';

export default function UserHome() {
  const navigate = useNavigate();
  const { session, logout } = useAuth();
  const toast = useSmartToast();
  const [tab, setTab] = useState('stadiums');
  const [cancelTarget, setCancelTarget] = useState(null);
  const [search, setSearch] = useState('');
  const errorShown = useRef(false);

  const fieldsQuery = useInfiniteFields();
  const bookingsQuery = useUserBookings();
  const notificationsQuery = useNotifications();
  const cancelMutation = useCancelBooking();
  const markReadMutation = useMarkNotificationsRead();
  useLiveUpdates(true);

  const fields = fieldsQuery.data?.pages.flat() ?? [];
  const bookings = bookingsQuery.data ?? [];
  const notifications = notificationsQuery.data ?? [];
  const isLoading = fieldsQuery.isLoading && !fields.length;
  const isRefetching = fieldsQuery.isFetching || bookingsQuery.isFetching || notificationsQuery.isFetching;
  const error = fieldsQuery.error || bookingsQuery.error || notificationsQuery.error;
  const visibleFields = fields.filter((field) => {
    const term = search.trim().toLocaleLowerCase();
    if (!term) return true;
    return `${field.name ?? ''} ${field.address ?? ''} ${field.category ?? ''}`.toLocaleLowerCase().includes(term);
  });

  const refetch = () => {
    fieldsQuery.refetch();
    bookingsQuery.refetch();
    notificationsQuery.refetch();
  };

  useEffect(() => {
    requestNotificationPermission();
  }, []);

  useEffect(() => {
    if (error && !fields.length && !errorShown.current) {
      errorShown.current = true;
      toast.smartError(error);
    }
    if (!error) errorShown.current = false;
  }, [error, fields.length, toast]);

  if (isLoading) return <FieldsListSkeleton />;

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const requestCancel = (booking) => {
    if (!booking.canCancel) {
      toast.warning('لا يمكن الإلغاء قبل أقل من 24 ساعة');
      return;
    }
    setCancelTarget(booking);
  };

  const confirmCancel = () => {
    if (!cancelTarget) return;
    cancelMutation.mutate(cancelTarget.id, {
      onSettled: () => setCancelTarget(null),
    });
  };

  const unread = notifications.filter((n) => !n.isRead).length;

  return (
    <PageTransition className="app-shell min-h-screen pb-28">
      <Header
        userName={session.user.name}
        avatar={session.user.image}
        onLogout={handleLogout}
        onSettings={() => navigate('/settings')}
        onHistory={() => navigate('/history')}
        subtitle="محافظة نينوى"
      />

      <main className="px-5 sm:px-6">
        {tab === 'stadiums' && (
          <>
            <section className="customer-hero relative overflow-hidden rounded-3xl mt-5 p-5 sm:p-7 text-white">
              <div className="absolute -left-8 -bottom-12 w-40 h-40 rounded-full border-[24px] border-white/5" aria-hidden="true" />
              <div className="relative z-10">
                <div className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-3 py-1.5 text-xs font-semibold text-green-200">
                  <Sparkles className="w-3.5 h-3.5" />
                  احجز لعبتك بسهولة
                </div>
                <h1 className="mt-4 text-2xl sm:text-3xl leading-tight font-extrabold tracking-tight">
                  وين تلعب اليوم؟
                </h1>
                <p className="mt-2 max-w-sm text-sm leading-6 text-white/70">
                  اكتشف الملاعب المتاحة في نينوى واختر الموعد المناسب إلك.
                </p>
                <label className="mt-5 flex items-center gap-3 rounded-2xl bg-white px-4 py-3.5 text-gray-900 shadow-lg">
                  <Search className="w-5 h-5 text-green-700 shrink-0" />
                  <input
                    type="search"
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="ابحث باسم الملعب أو المنطقة"
                    className="w-full min-w-0 bg-transparent text-sm outline-none placeholder:text-gray-400"
                    aria-label="ابحث باسم الملعب أو المنطقة"
                  />
                  {search && (
                    <button type="button" onClick={() => setSearch('')} className="text-xs font-bold text-green-800">
                      مسح
                    </button>
                  )}
                </label>
              </div>
            </section>

            <div className="flex items-end justify-between gap-3 mt-7 mb-4">
              <div>
                <h2 className="customer-section-title text-xl font-extrabold">اكتشف الملاعب</h2>
                <p className="text-sm mt-1 text-[rgb(var(--color-on-surface-variant))]">
                  {search ? `نتائج البحث: ${visibleFields.length}` : 'اختار المكان المناسب لمباراتك'}
                </p>
              </div>
              <button
                type="button"
                onClick={refetch}
                className="h-10 w-10 rounded-xl border border-[rgb(var(--color-outline))] bg-[rgb(var(--color-surface))] grid place-items-center text-[rgb(var(--color-on-surface-variant))]"
                aria-label="تحديث الملاعب"
              >
                <RefreshCw className={`w-4 h-4 ${isRefetching ? 'animate-spin' : ''}`} />
              </button>
            </div>

            {isRefetching && (
              <div className="flex justify-center py-1">
                <RefreshCw className="w-4 h-4 text-[rgb(var(--color-primary))] animate-spin opacity-70" />
              </div>
            )}

            {error && !fields.length ? (
              <EmptyState
                icon={Building2}
                title="تعذّر تحميل الملاعب"
                subtitle="تحقق من اتصالك بالإنترنت وحاول مجدداً"
                onAction={refetch}
              />
            ) : visibleFields.length === 0 ? (
              <EmptyState
                icon={Building2}
                title={search ? 'ما لقينا نتائج مطابقة' : 'لا توجد ملاعب حالياً'}
                subtitle={search ? 'جرّب اسم ملعب أو منطقة ثانية' : 'سيتم عرض الملاعب عند توفرها'}
                onAction={search ? () => setSearch('') : refetch}
              />
            ) : (
              <StaggerList className="grid grid-cols-1 gap-3 sm:gap-4">
                {visibleFields.map((stadium) => (
                  <StaggerItem key={stadium.id}>
                    <StadiumCard stadium={stadium} onClick={() => navigate(`/stadium/${stadium.id}`, { state: { stadium } })} />
                  </StaggerItem>
                ))}
              </StaggerList>
            )}
            {fieldsQuery.hasNextPage && !search && (
              <div className="text-center py-5">
                <Button
                  variant="secondary"
                  loading={fieldsQuery.isFetchingNextPage}
                  onClick={() => fieldsQuery.fetchNextPage()}
                >
                  تحميل المزيد
                </Button>
              </div>
            )}
          </>
        )}

        {tab === 'bookings' && (
          <section className="pt-6">
            <h2 className="font-extrabold text-xl mb-4">حجوزاتي</h2>
            {bookings.length === 0 ? (
              <EmptyState icon={Calendar} title="لا توجد حجوزات" subtitle="احجز ملعباً من تبويب الملاعب للبدء" />
            ) : (
              <div className="space-y-3">
                {bookings.map((b) => (
                  <div key={b.id} className="card">
                    <div className="flex items-start justify-between gap-3 mb-3">
                      <Badge status={b.status} />
                      <h3 className="font-bold text-lg">{b.fieldName ?? b.stadiumName}</h3>
                    </div>
                    <div className="space-y-2 text-sm text-[rgb(var(--color-on-surface-variant))]">
                      {(b.fieldAddress ?? b.stadiumAddress) && <p className="flex items-center gap-2 justify-end"><MapPin className="w-4 h-4 text-[rgb(var(--color-primary))]" />{b.fieldAddress ?? b.stadiumAddress}</p>}
                      {(b.fieldPhone ?? b.stadiumPhone) && <p className="flex items-center gap-2 justify-end"><Phone className="w-4 h-4 text-[rgb(var(--color-primary))]" />{b.fieldPhone ?? b.stadiumPhone}</p>}
                      <p className="flex items-center gap-2 justify-end"><Clock className="w-4 h-4 text-[rgb(var(--color-primary))]" />{formatDateTime(b.startTime)}</p>
                      <p className="flex items-center gap-2 justify-end font-extrabold text-[rgb(var(--color-primary))]">
                        {b.hours} ساعة — {formatMoney(b.totalPrice)}
                      </p>
                    </div>
                    {b.status === 'approved' && (
                      <div className="mt-3 p-3 rounded-xl bg-green-500/10 flex items-center gap-2 justify-end">
                        <span className="font-bold text-sm text-[rgb(var(--color-primary))]">{formatRemaining(b.remainingHours)}</span>
                        <Timer className="w-4 h-4 text-[rgb(var(--color-primary))]" />
                      </div>
                    )}
                    {(b.status === 'pending' || b.status === 'approved') && (
                      <Button
                        variant="danger"
                        className={`mt-3 !py-2.5 text-sm ${!b.canCancel ? 'opacity-40' : ''}`}
                        onClick={() => requestCancel(b)}
                        loading={cancelMutation.isPending && cancelTarget?.id === b.id}
                      >
                        <XCircle className="w-4 h-4" /> إلغاء الحجز
                      </Button>
                    )}
                  </div>
                ))}
              </div>
            )}
          </section>
        )}

        {tab === 'notifications' && (
          <section className="pt-6">
            <div className="flex items-center justify-between gap-3 mb-4">
              <h2 className="font-extrabold text-xl">الإشعارات</h2>
              {unread > 0 && (
                <button
                  type="button"
                  className="text-sm text-[rgb(var(--color-primary))] font-bold"
                  onClick={() => markReadMutation.mutate({ all: true })}
                >
                  تعليم الكل كمقروء
                </button>
              )}
            </div>
            {notifications.length === 0 ? (
              <EmptyState icon={Bell} title="لا توجد إشعارات" subtitle="ستظهر هنا تحديثات حجوزاتك" />
            ) : (
              <div className="space-y-2">
                {notifications.map((n) => (
                  <button
                    key={n.id}
                    type="button"
                    onClick={() => !n.isRead && markReadMutation.mutate({ id: n.id })}
                    className={`card w-full text-right ${n.isRead ? 'opacity-60' : 'border-r-4 border-r-[rgb(var(--color-primary))]'}`}
                  >
                    <p className="font-bold">{n.title}</p>
                    <p className="text-[rgb(var(--color-on-surface-variant))] text-sm mt-1">{n.message}</p>
                  </button>
                ))}
              </div>
            )}
          </section>
        )}
      </main>

      <BottomNav active={tab} onChange={setTab} badges={{ notifications: unread }} />

      <ConfirmDialog
        open={!!cancelTarget}
        title="إلغاء الحجز"
        message="هل أنت متأكد من إلغاء هذا الحجز؟ لا يمكن الإلغاء قبل أقل من 24 ساعة من موعد اللعب."
        confirmLabel="نعم، إلغاء"
        cancelLabel="تراجع"
        loading={cancelMutation.isPending}
        onConfirm={confirmCancel}
        onCancel={() => setCancelTarget(null)}
      />
    </PageTransition>
  );
}
