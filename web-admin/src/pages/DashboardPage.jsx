import { useMemo } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  Users, Building2, CalendarDays, Wallet, BadgeCheck, Clock3,
  ArrowUpRight, RefreshCw, TrendingUp, AlertTriangle,
} from 'lucide-react';
import { api, formatDate, formatMoney } from '../lib/api';
import { ErrorBlock, LoadingBlock, StatCard, StatusBadge } from '../components/ui';
import { BarChart, DonutChart, ProgressBar } from '../components/Charts';
import { useAuth } from '../context/AuthContext';

export default function DashboardPage() {
  const { user } = useAuth();
  const qc = useQueryClient();

  const stats = useQuery({ queryKey: ['admin-stats'], queryFn: api.stats, refetchInterval: 60_000 });
  const financials = useQuery({ queryKey: ['admin-financials'], queryFn: api.financials, refetchInterval: 60_000 });
  const pending = useQuery({ queryKey: ['admin-pending'], queryFn: api.pendingBookings, refetchInterval: 30_000 });
  const bookings = useQuery({
    queryKey: ['admin-bookings-dash'],
    queryFn: () => api.bookings({ status: 'all', limit: 100 }),
    refetchInterval: 60_000,
  });
  const fields = useQuery({ queryKey: ['admin-fields'], queryFn: api.fields });
  const owners = useQuery({ queryKey: ['admin-owners'], queryFn: api.owners });

  const allBookings = bookings.data?.items || [];

  const statusCounts = useMemo(() => {
    const map = { pending: 0, approved: 0, rejected: 0, cancelled: 0 };
    for (const b of allBookings) {
      if (map[b.status] != null) map[b.status] += 1;
      else map[b.status] = (map[b.status] || 0) + 1;
    }
    return map;
  }, [allBookings]);

  const topFields = useMemo(() => {
    const counts = {};
    for (const b of allBookings) {
      const name = b.fieldName || 'غير معروف';
      counts[name] = (counts[name] || 0) + 1;
    }
    return Object.entries(counts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 6)
      .map(([label, value]) => ({ label: label.length > 10 ? `${label.slice(0, 10)}…` : label, value }));
  }, [allBookings]);

  const approve = useMutation({
    mutationFn: (id) => api.approveBooking(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-pending'] });
      qc.invalidateQueries({ queryKey: ['admin-bookings'] });
      qc.invalidateQueries({ queryKey: ['admin-bookings-dash'] });
      qc.invalidateQueries({ queryKey: ['admin-stats'] });
    },
  });
  const reject = useMutation({
    mutationFn: (id) => api.rejectBooking(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-pending'] });
      qc.invalidateQueries({ queryKey: ['admin-bookings-dash'] });
      qc.invalidateQueries({ queryKey: ['admin-stats'] });
    },
  });

  const loading = stats.isLoading || financials.isLoading || bookings.isLoading;
  if (loading) return <LoadingBlock />;
  if (stats.isError) return <ErrorBlock error={stats.error} onRetry={stats.refetch} />;

  const s = stats.data || {};
  const f = financials.data || {};
  const pendingList = pending.data || [];
  const fieldList = fields.data || [];
  const ownerList = owners.data || [];

  const statusSegments = [
    { label: 'معلّق', value: statusCounts.pending || 0, color: '#d97706' },
    { label: 'موافق', value: statusCounts.approved || 0, color: '#2d6a3e' },
    { label: 'مرفوض', value: statusCounts.rejected || 0, color: '#dc2626' },
    { label: 'ملغى', value: statusCounts.cancelled || 0, color: '#78716c' },
  ];

  const activeFields = fieldList.filter((x) => x.isActive).length;
  const blockedOwners = ownerList.filter((x) => x.walletStatus === 'blocked').length;
  const totalRevenue = Number(s.totalRevenueIqd) || 0;
  const commission = Number(s.platformCommissionIqd) || 0;
  const paid = Number(f.paidBookings ?? s.paidBookings) || 0;
  const totalBookings = Number(s.totalBookings) || 0;
  const conversion = totalBookings ? Math.round((paid / totalBookings) * 100) : 0;

  const nowLabel = new Date().toLocaleString('ar-IQ', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit',
  });

  const refreshAll = () => {
    stats.refetch();
    financials.refetch();
    pending.refetch();
    bookings.refetch();
    fields.refetch();
    owners.refetch();
  };

  return (
    <div className="space-y-6">
      <section className="overflow-hidden rounded-3xl border border-pitch-800/20 bg-pitch-950 text-white shadow-panel">
        <div className="relative px-6 py-7 lg:px-8">
          <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(700px_280px_at_0%_0%,rgba(94,163,111,0.35),transparent_60%)]" />
          <div className="relative flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="text-xs font-semibold tracking-wide text-pitch-300">لوحة تشغيل المنصة · نينوى</p>
              <h1 className="mt-2 text-3xl font-bold tracking-tight lg:text-4xl">
                مرحباً{user?.name ? `، ${user.name}` : ''}
              </h1>
              <p className="mt-2 max-w-xl text-sm text-pitch-200/90">
                مراقبة الحجوزات والإيرادات والملاعب لحظة بلحظة — متصلة مباشرة بسيرفر الإنتاج.
              </p>
              <p className="mt-3 text-xs text-pitch-400">{nowLabel}</p>
            </div>
            <div className="flex flex-wrap gap-2">
              <button type="button" className="btn !bg-white/10 !text-white hover:!bg-white/20" onClick={refreshAll}>
                <RefreshCw className="h-4 w-4" />
                تحديث
              </button>
              <Link to="/bookings?status=pending" className="btn !bg-amber-500 !text-white hover:!bg-amber-600">
                <AlertTriangle className="h-4 w-4" />
                معلّق ({pendingList.length})
              </Link>
              <Link to="/bookings" className="btn !bg-pitch-600 !text-white hover:!bg-pitch-500">
                كل الحجوزات
                <ArrowUpRight className="h-4 w-4" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard icon={Users} label="المستخدمون" value={s.totalUsers ?? 0} hint="حسابات اللاعبين" />
        <StatCard icon={Wallet} label="الملاك" value={s.totalOwners ?? 0} hint={blockedOwners ? `${blockedOwners} محفظة موقوفة` : 'كل المحافظ نشطة'} tone="info" />
        <StatCard icon={Building2} label="الملاعب" value={s.totalFields ?? 0} hint={`${activeFields} نشط / ${(s.totalFields || 0) - activeFields} متوقف`} />
        <StatCard icon={CalendarDays} label="الحجوزات" value={totalBookings} hint={`${statusCounts.pending || 0} بانتظار القرار`} tone="warn" />
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard icon={TrendingUp} label="إجمالي الإيرادات" value={formatMoney(totalRevenue)} hint="حجوزات موافق عليها" tone="money" />
        <StatCard icon={BadgeCheck} label="عمولة المنصة 10%" value={formatMoney(commission)} tone="money" />
        <StatCard icon={Clock3} label="مدفوعة / نقدية" value={paid} hint={`نسبة التحصيل ${conversion}%`} />
        <StatCard icon={AlertTriangle} label="يحتاج إجراء" value={pendingList.length} hint="حجوزات معلّقة الآن" tone="warn" />
      </div>

      <div className="grid gap-4 xl:grid-cols-12">
        <section className="panel p-5 xl:col-span-5">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="font-bold text-pitch-950">توزيع حالات الحجوزات</h2>
            <span className="text-xs text-pitch-500">آخر 100 حجز</span>
          </div>
          <DonutChart segments={statusSegments} />
        </section>

        <section className="panel p-5 xl:col-span-4">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="font-bold text-pitch-950">أكثر الملاعب نشاطاً</h2>
          </div>
          {topFields.length ? (
            <BarChart data={topFields} height={200} />
          ) : (
            <p className="py-10 text-center text-sm text-pitch-500">لا بيانات كافية بعد</p>
          )}
        </section>

        <section className="panel flex flex-col gap-4 p-5 xl:col-span-3">
          <h2 className="font-bold text-pitch-950">صحة المنصة</h2>
          <ProgressBar label="الملاعب النشطة" value={activeFields} max={Math.max(1, fieldList.length)} color="bg-pitch-600" />
          <ProgressBar label="تحصيل الحجوزات" value={paid} max={Math.max(1, totalBookings)} color="bg-emerald-600" />
          <ProgressBar label="موافقة الحجوزات" value={statusCounts.approved || 0} max={Math.max(1, totalBookings)} color="bg-sky-600" />
          <div className="mt-auto rounded-xl bg-pitch-50 px-3 py-3 text-xs text-pitch-700">
            <p className="font-semibold">صافي الملاك التقريبي</p>
            <p className="mt-1 text-lg font-bold text-pitch-950">{formatMoney(totalRevenue - commission)}</p>
          </div>
        </section>
      </div>

      <div className="grid gap-4 xl:grid-cols-12">
        <section className="panel overflow-hidden xl:col-span-8">
          <div className="flex items-center justify-between border-b border-pitch-100 px-5 py-4">
            <div>
              <h2 className="font-bold text-pitch-950">طابور الموافقات</h2>
              <p className="text-xs text-pitch-500">أحدث الحجوزات المعلقة — إجراء مباشر</p>
            </div>
            <Link to="/bookings?status=pending" className="text-sm font-semibold text-pitch-700 hover:underline">
              عرض الكل
            </Link>
          </div>

          {!pendingList.length ? (
            <div className="px-5 py-12 text-center text-sm text-pitch-500">لا توجد حجوزات معلّقة — المنصة مستقرّة</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full text-sm">
                <thead className="bg-pitch-50/80 text-pitch-700">
                  <tr>
                    <th className="px-4 py-3 text-right font-semibold">الملعب</th>
                    <th className="px-4 py-3 text-right font-semibold">المستخدم</th>
                    <th className="px-4 py-3 text-right font-semibold">الوقت</th>
                    <th className="px-4 py-3 text-right font-semibold">المبلغ</th>
                    <th className="px-4 py-3 text-right font-semibold">إجراء</th>
                  </tr>
                </thead>
                <tbody>
                  {pendingList.slice(0, 8).map((b) => (
                    <tr key={b.id} className="border-t border-pitch-100 hover:bg-pitch-50/50">
                      <td className="px-4 py-3 font-medium">{b.fieldName}</td>
                      <td className="px-4 py-3">{b.userName}</td>
                      <td className="px-4 py-3 whitespace-nowrap">{formatDate(b.startTime)}</td>
                      <td className="px-4 py-3 whitespace-nowrap font-semibold">{formatMoney(b.totalPrice)}</td>
                      <td className="px-4 py-3">
                        <div className="flex flex-wrap gap-1.5">
                          <button
                            type="button"
                            className="btn-primary !px-2.5 !py-1.5 !text-xs"
                            disabled={approve.isPending}
                            onClick={() => approve.mutate(b.id)}
                          >
                            موافقة
                          </button>
                          <button
                            type="button"
                            className="btn-danger !px-2.5 !py-1.5 !text-xs"
                            disabled={reject.isPending}
                            onClick={() => reject.mutate(b.id)}
                          >
                            رفض
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>

        <section className="panel p-5 xl:col-span-4">
          <h2 className="mb-4 font-bold text-pitch-950">اختصارات التشغيل</h2>
          <div className="grid gap-2">
            {[
              { to: '/owners', title: 'الملاك والمحافظ', desc: 'شحن · إيقاف · تفاصيل' },
              { to: '/fields', title: 'إدارة الملاعب', desc: 'تفعيل وإيقاف وتعديل' },
              { to: '/users', title: 'المستخدمون', desc: 'بحث وعرض الحسابات' },
              { to: '/bookings', title: 'سجل الحجوزات', desc: 'فلترة حسب الحالة' },
            ].map((item) => (
              <Link
                key={item.to}
                to={item.to}
                className="group flex items-center justify-between rounded-xl border border-pitch-100 bg-pitch-50/60 px-4 py-3 transition hover:border-pitch-300 hover:bg-white"
              >
                <div>
                  <p className="text-sm font-bold text-pitch-900">{item.title}</p>
                  <p className="text-xs text-pitch-500">{item.desc}</p>
                </div>
                <ArrowUpRight className="h-4 w-4 text-pitch-400 transition group-hover:text-pitch-700" />
              </Link>
            ))}
          </div>

          <div className="mt-5 rounded-xl border border-dashed border-pitch-200 px-4 py-3 text-xs text-pitch-600">
            <p className="font-semibold text-pitch-800">حالة الاتصال</p>
            <p className="mt-1">API: sports-x7v7.onrender.com · مباشر</p>
            <div className="mt-2 flex items-center gap-2">
              <span className="h-2 w-2 rounded-full bg-emerald-500" />
              <span>البيانات تُحدَّث تلقائياً كل دقيقة</span>
            </div>
          </div>
        </section>
      </div>

      <section className="panel overflow-hidden">
        <div className="flex items-center justify-between border-b border-pitch-100 px-5 py-4">
          <h2 className="font-bold text-pitch-950">آخر الحجوزات على المنصة</h2>
          <Link to="/bookings" className="text-sm font-semibold text-pitch-700 hover:underline">التفاصيل</Link>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-pitch-50/80 text-pitch-700">
              <tr>
                <th className="px-4 py-3 text-right">المرجع</th>
                <th className="px-4 py-3 text-right">الملعب</th>
                <th className="px-4 py-3 text-right">المستخدم</th>
                <th className="px-4 py-3 text-right">الوقت</th>
                <th className="px-4 py-3 text-right">الحالة</th>
                <th className="px-4 py-3 text-right">الدفع</th>
                <th className="px-4 py-3 text-right">المبلغ</th>
              </tr>
            </thead>
            <tbody>
              {allBookings.slice(0, 10).map((b) => (
                <tr key={b.id} className="border-t border-pitch-100">
                  <td className="px-4 py-3 font-mono text-xs">{b.referenceCode || b.id}</td>
                  <td className="px-4 py-3 font-medium">{b.fieldName}</td>
                  <td className="px-4 py-3">{b.userName}</td>
                  <td className="px-4 py-3 whitespace-nowrap">{formatDate(b.startTime)}</td>
                  <td className="px-4 py-3"><StatusBadge status={b.status} /></td>
                  <td className="px-4 py-3"><StatusBadge status={b.paymentStatus} /></td>
                  <td className="px-4 py-3 font-semibold">{formatMoney(b.totalPrice)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {!allBookings.length ? (
            <p className="px-5 py-8 text-center text-sm text-pitch-500">لا حجوزات بعد</p>
          ) : null}
        </div>
      </section>
    </div>
  );
}
