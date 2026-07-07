import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { MapPin, Phone, Clock, Timer, XCircle, RefreshCw, History, Building2, Calendar, Bell } from 'lucide-react';
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
    <PageTransition className="app-shell min-h-screen pb-24">
      <Header
        userName={session.user.name}
        avatar={session.user.image}
        onLogout={handleLogout}
        onSettings={() => navigate('/settings')}
        onHistory={() => navigate('/history')}
        subtitle="محافظة نينوى"
      />

      {isRefetching && (
        <div className="flex justify-center py-1">
          <RefreshCw className="w-4 h-4 text-brand-500 animate-spin opacity-60" />
        </div>
      )}

      <div className="px-5 -mt-2">
        {tab === 'stadiums' && (
          <div>
            <h2 className="font-bold text-lg mb-4 text-right">الملاعب المتاحة</h2>
            {error && !fields.length ? (
              <EmptyState
                icon={Building2}
                title="تعذّر تحميل الملاعب"
                subtitle="تحقق من اتصالك بالإنترنت وحاول مجدداً"
                onAction={refetch}
              />
            ) : fields.length === 0 ? (
              <EmptyState
                icon={Building2}
                title="لا توجد ملاعب حالياً"
                subtitle="سيتم إضافة ملاعب جديدة قريباً — حاول لاحقاً"
                onAction={refetch}
              />
            ) : (
              <StaggerList className="space-y-3">
                {fields.map((s) => (
                  <StaggerItem key={s.id}>
                    <StadiumCard stadium={s} onClick={() => navigate(`/stadium/${s.id}`, { state: { stadium: s } })} />
                  </StaggerItem>
                ))}
              </StaggerList>
            )}
            {fieldsQuery.hasNextPage && (
              <div className="text-center py-4">
                <Button
                  variant="secondary"
                  loading={fieldsQuery.isFetchingNextPage}
                  onClick={() => fieldsQuery.fetchNextPage()}
                >
                  تحميل المزيد
                </Button>
              </div>
            )}
          </div>
        )}

        {tab === 'bookings' && (
          <div>
            <h2 className="font-bold text-lg mb-4 text-right">حجوزاتي</h2>
            {bookings.length === 0 ? (
              <EmptyState
                icon={Calendar}
                title="لا توجد حجوزات"
                subtitle="احجز ملعباً من تبويب الملاعب للبدء"
              />
            ) : (
              <div className="space-y-3">
                {bookings.map((b) => (
                  <div key={b.id} className="card">
                    <div className="flex items-start justify-between mb-3">
                      <Badge status={b.status} />
                      <h3 className="font-bold text-brand-700 text-lg">{b.fieldName ?? b.stadiumName}</h3>
                    </div>

                    <div className="space-y-2 text-sm text-gray-600">
                      <p className="flex items-center gap-2 justify-end"><MapPin className="w-4 h-4 text-brand-500" />{b.fieldAddress ?? b.stadiumAddress}</p>
                      <p className="flex items-center gap-2 justify-end"><Phone className="w-4 h-4 text-brand-500" />{b.fieldPhone ?? b.stadiumPhone}</p>
                      <p className="flex items-center gap-2 justify-end"><Clock className="w-4 h-4 text-brand-500" />{formatDateTime(b.startTime)}</p>
                      <p className="flex items-center gap-2 justify-end font-bold text-brand-600">
                        {b.hours} ساعة — {formatMoney(b.totalPrice)}
                      </p>
                    </div>

                    {b.status === 'approved' && (
                      <div className="mt-3 p-3 rounded-xl bg-green-50 flex items-center gap-2 justify-end">
                        <span className="text-green-700 font-bold text-sm">{formatRemaining(b.remainingHours)}</span>
                        <Timer className="w-4 h-4 text-green-600" />
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
          </div>
        )}

        {tab === 'notifications' && (
          <div>
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-bold text-lg text-right">الإشعارات</h2>
              {unread > 0 && (
                <button
                  type="button"
                  className="text-sm text-brand-600 font-semibold"
                  onClick={() => markReadMutation.mutate({ all: true })}
                >
                  تعليم الكل كمقروء
                </button>
              )}
            </div>
            {notifications.length === 0 ? (
              <EmptyState
                icon={Bell}
                title="لا توجد إشعارات"
                subtitle="ستظهر هنا تحديثات حجوزاتك"
              />
            ) : (
              <div className="space-y-2">
                {notifications.map((n) => (
                  <button
                    key={n.id}
                    type="button"
                    onClick={() => !n.isRead && markReadMutation.mutate({ id: n.id })}
                    className={`card w-full text-right ${n.isRead ? 'opacity-60' : 'border-r-4 border-r-brand-500'}`}
                  >
                    <p className="font-bold text-brand-700">{n.title}</p>
                    <p className="text-gray-600 text-sm mt-1">{n.message}</p>
                  </button>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

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
