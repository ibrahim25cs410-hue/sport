import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { api, formatMoney } from '../lib/api';
import { ErrorBlock, LoadingBlock, PageHeader, StatCard } from '../components/ui';

export default function DashboardPage() {
  const stats = useQuery({ queryKey: ['admin-stats'], queryFn: api.stats });
  const financials = useQuery({ queryKey: ['admin-financials'], queryFn: api.financials });
  const pending = useQuery({ queryKey: ['admin-pending'], queryFn: api.pendingBookings });

  if (stats.isLoading || financials.isLoading) return <LoadingBlock />;
  if (stats.isError) return <ErrorBlock error={stats.error} onRetry={stats.refetch} />;

  const s = stats.data || {};
  const f = financials.data || {};
  const pendingCount = pending.data?.length || 0;

  return (
    <div>
      <PageHeader
        title="لوحة التحكم"
        subtitle="نظرة شاملة على المنصة مباشرة من قاعدة الإنتاج"
        actions={
          <Link to="/bookings?status=pending" className="btn-primary">
            الحجوزات المعلقة ({pendingCount})
          </Link>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="المستخدمون" value={s.totalUsers ?? 0} />
        <StatCard label="الملاك" value={s.totalOwners ?? 0} />
        <StatCard label="الملاعب" value={s.totalFields ?? 0} />
        <StatCard label="إجمالي الحجوزات" value={s.totalBookings ?? 0} />
      </div>

      <div className="mt-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <StatCard label="إيرادات الحجوزات" value={formatMoney(s.totalRevenueIqd)} hint="من الحجوزات الموافق عليها" />
        <StatCard label="عمولة المنصة (10%)" value={formatMoney(s.platformCommissionIqd)} />
        <StatCard label="حجوزات مدفوعة/نقدية" value={f.paidBookings ?? s.paidBookings ?? 0} />
      </div>

      <section className="panel mt-6 overflow-hidden">
        <div className="border-b border-pitch-100 px-5 py-4">
          <h2 className="font-bold">أحدث الحجوزات المعلقة</h2>
        </div>
        {pending.isLoading ? (
          <div className="p-5 text-sm text-pitch-600">جاري التحميل...</div>
        ) : !pending.data?.length ? (
          <div className="p-5 text-sm text-pitch-500">لا توجد حجوزات معلقة حالياً</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="bg-pitch-50 text-pitch-700">
                <tr>
                  <th className="px-4 py-3 text-right font-semibold">الملعب</th>
                  <th className="px-4 py-3 text-right font-semibold">المستخدم</th>
                  <th className="px-4 py-3 text-right font-semibold">الوقت</th>
                  <th className="px-4 py-3 text-right font-semibold">المبلغ</th>
                </tr>
              </thead>
              <tbody>
                {pending.data.slice(0, 8).map((b) => (
                  <tr key={b.id} className="border-t border-pitch-100">
                    <td className="px-4 py-3 font-medium">{b.fieldName}</td>
                    <td className="px-4 py-3">{b.userName}</td>
                    <td className="px-4 py-3">{new Date(b.startTime).toLocaleString('ar-IQ')}</td>
                    <td className="px-4 py-3">{formatMoney(b.totalPrice)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
