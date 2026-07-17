import { Link, useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { api, formatDate, formatMoney } from '../lib/api';
import { ErrorBlock, LoadingBlock, PageHeader, StatCard, StatusBadge } from '../components/ui';

export default function OwnerDetailPage() {
  const { ownerId } = useParams();
  const detail = useQuery({
    queryKey: ['admin-owner', ownerId],
    queryFn: () => api.owner(ownerId),
  });

  if (detail.isLoading) return <LoadingBlock />;
  if (detail.isError) return <ErrorBlock error={detail.error} onRetry={detail.refetch} />;

  const { owner, dashboard, wallet, payments } = detail.data;
  const txs = wallet?.transactions || [];

  return (
    <div>
      <PageHeader
        title={owner.name}
        subtitle={`${owner.email} · ${owner.phone || 'بدون هاتف'}`}
        actions={<Link to="/owners" className="btn-ghost">رجوع للملاك</Link>}
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="إيرادات الحجوزات" value={formatMoney(dashboard.totalRevenue)} />
        <StatCard label="عمولة المنصة" value={formatMoney(dashboard.appCommission)} />
        <StatCard label="صافي المالك" value={formatMoney(dashboard.netRevenue)} />
        <StatCard label="رصيد المحفظة" value={formatMoney(wallet?.balance)} hint={wallet?.status} />
      </div>

      <div className="mt-4 grid gap-4 lg:grid-cols-2">
        <section className="panel overflow-hidden">
          <div className="border-b border-pitch-100 px-5 py-4 font-bold">حجوزات المالك</div>
          <div className="max-h-96 overflow-auto">
            <table className="min-w-full text-sm">
              <thead className="bg-pitch-50 text-pitch-700">
                <tr>
                  <th className="px-3 py-2 text-right">الملعب</th>
                  <th className="px-3 py-2 text-right">المستخدم</th>
                  <th className="px-3 py-2 text-right">الحالة</th>
                  <th className="px-3 py-2 text-right">المبلغ</th>
                </tr>
              </thead>
              <tbody>
                {(dashboard.bookings || []).map((b) => (
                  <tr key={b.id} className="border-t border-pitch-100">
                    <td className="px-3 py-2">{b.fieldName}</td>
                    <td className="px-3 py-2">{b.userName}</td>
                    <td className="px-3 py-2"><StatusBadge status={b.status} /></td>
                    <td className="px-3 py-2">{formatMoney(b.totalPrice)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!dashboard.bookings?.length ? <p className="p-4 text-sm text-pitch-500">لا حجوزات</p> : null}
          </div>
        </section>

        <section className="panel overflow-hidden">
          <div className="border-b border-pitch-100 px-5 py-4 font-bold">
            حركات المحفظة
            <span className="mr-2 text-xs font-normal text-pitch-500">
              مستحق عمولة: {formatMoney(payments?.outstandingAmount)}
            </span>
          </div>
          <div className="max-h-96 overflow-auto">
            <table className="min-w-full text-sm">
              <thead className="bg-pitch-50 text-pitch-700">
                <tr>
                  <th className="px-3 py-2 text-right">النوع</th>
                  <th className="px-3 py-2 text-right">المبلغ</th>
                  <th className="px-3 py-2 text-right">الوصف</th>
                  <th className="px-3 py-2 text-right">التاريخ</th>
                </tr>
              </thead>
              <tbody>
                {txs.map((t) => (
                  <tr key={t.id} className="border-t border-pitch-100">
                    <td className="px-3 py-2">{t.typeLabel || t.type}</td>
                    <td className={`px-3 py-2 font-semibold ${t.amount >= 0 ? 'text-pitch-700' : 'text-red-600'}`}>
                      {formatMoney(t.amount)}
                    </td>
                    <td className="px-3 py-2">{t.description}</td>
                    <td className="px-3 py-2 whitespace-nowrap">{formatDate(t.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!txs.length ? <p className="p-4 text-sm text-pitch-500">لا حركات بعد</p> : null}
          </div>
        </section>
      </div>
    </div>
  );
}
