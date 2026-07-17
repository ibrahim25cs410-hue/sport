import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSearchParams } from 'react-router-dom';
import { api, formatDate, formatMoney } from '../lib/api';
import { EmptyBlock, ErrorBlock, LoadingBlock, PageHeader, StatusBadge } from '../components/ui';

const STATUS_FILTERS = [
  { id: 'all', label: 'الكل' },
  { id: 'pending', label: 'معلّق' },
  { id: 'approved', label: 'موافق' },
  { id: 'rejected', label: 'مرفوض' },
  { id: 'cancelled', label: 'ملغى' },
];

export default function BookingsPage() {
  const [params, setParams] = useSearchParams();
  const status = params.get('status') || 'all';
  const [q, setQ] = useState('');
  const [msg, setMsg] = useState('');
  const qc = useQueryClient();

  const query = useQuery({
    queryKey: ['admin-bookings', status, q],
    queryFn: () => api.bookings({ status, q, limit: 100 }),
  });

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ['admin-bookings'] });
    qc.invalidateQueries({ queryKey: ['admin-pending'] });
    qc.invalidateQueries({ queryKey: ['admin-stats'] });
  };

  const approve = useMutation({
    mutationFn: (id) => api.approveBooking(id),
    onSuccess: () => { setMsg('تمت الموافقة'); invalidate(); },
    onError: (e) => setMsg(e.message),
  });
  const reject = useMutation({
    mutationFn: (id) => api.rejectBooking(id),
    onSuccess: () => { setMsg('تم الرفض'); invalidate(); },
    onError: (e) => setMsg(e.message),
  });
  const cancel = useMutation({
    mutationFn: (id) => api.cancelBooking(id),
    onSuccess: () => { setMsg('تم الإلغاء'); invalidate(); },
    onError: (e) => setMsg(e.message),
  });
  const confirmPay = useMutation({
    mutationFn: (id) => api.confirmCashPayment(id),
    onSuccess: () => { setMsg('تم تأكيد الدفع النقدي'); invalidate(); },
    onError: (e) => setMsg(e.message),
  });

  const items = useMemo(() => query.data?.items || [], [query.data]);

  return (
    <div>
      <PageHeader
        title="الحجوزات"
        subtitle="موافقة / رفض / إلغاء وتأكيد الدفع النقدي مباشرة على المنصة"
      />

      <div className="mb-4 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex flex-wrap gap-2">
          {STATUS_FILTERS.map((f) => (
            <button
              key={f.id}
              type="button"
              className={`rounded-full px-3 py-1.5 text-sm font-semibold ${
                status === f.id ? 'bg-pitch-700 text-white' : 'bg-white text-pitch-700 border border-pitch-200'
              }`}
              onClick={() => {
                const next = new URLSearchParams(params);
                if (f.id === 'all') next.delete('status');
                else next.set('status', f.id);
                setParams(next);
              }}
            >
              {f.label}
            </button>
          ))}
        </div>
        <input
          className="input max-w-sm"
          placeholder="بحث بالملعب / المستخدم / المرجع"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>

      {msg ? <div className="mb-4 rounded-xl bg-pitch-50 px-3 py-2 text-sm text-pitch-800">{msg}</div> : null}

      {query.isLoading ? <LoadingBlock /> : null}
      {query.isError ? <ErrorBlock error={query.error} onRetry={query.refetch} /> : null}
      {!query.isLoading && !query.isError && !items.length ? (
        <EmptyBlock title="لا توجد حجوزات" hint="جرّب تغيير الفلتر أو البحث" />
      ) : null}

      {items.length ? (
        <div className="panel overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-pitch-50 text-pitch-700">
              <tr>
                <th className="px-3 py-3 text-right">#</th>
                <th className="px-3 py-3 text-right">الملعب</th>
                <th className="px-3 py-3 text-right">المستخدم</th>
                <th className="px-3 py-3 text-right">الوقت</th>
                <th className="px-3 py-3 text-right">المبلغ</th>
                <th className="px-3 py-3 text-right">الحالة</th>
                <th className="px-3 py-3 text-right">الدفع</th>
                <th className="px-3 py-3 text-right">إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {items.map((b) => (
                <tr key={b.id} className="border-t border-pitch-100 align-top">
                  <td className="px-3 py-3 font-mono text-xs">{b.referenceCode || b.id}</td>
                  <td className="px-3 py-3 font-medium">{b.fieldName}</td>
                  <td className="px-3 py-3">
                    <div>{b.userName}</div>
                    <div className="text-xs text-pitch-500">{b.userPhone}</div>
                  </td>
                  <td className="px-3 py-3 whitespace-nowrap">
                    <div>{formatDate(b.startTime)}</div>
                    <div className="text-xs text-pitch-500">{b.hours} ساعة</div>
                  </td>
                  <td className="px-3 py-3 whitespace-nowrap">{formatMoney(b.totalPrice)}</td>
                  <td className="px-3 py-3"><StatusBadge status={b.status} /></td>
                  <td className="px-3 py-3"><StatusBadge status={b.paymentStatus} /></td>
                  <td className="px-3 py-3">
                    <div className="flex min-w-[180px] flex-wrap gap-1.5">
                      {b.status === 'pending' ? (
                        <>
                          <button type="button" className="btn-primary !px-2.5 !py-1.5 !text-xs" onClick={() => approve.mutate(b.id)}>موافقة</button>
                          <button type="button" className="btn-danger !px-2.5 !py-1.5 !text-xs" onClick={() => reject.mutate(b.id)}>رفض</button>
                        </>
                      ) : null}
                      {(b.status === 'pending' || b.status === 'approved') ? (
                        <button type="button" className="btn-ghost !px-2.5 !py-1.5 !text-xs" onClick={() => cancel.mutate(b.id)}>إلغاء</button>
                      ) : null}
                      {b.paymentStatus === 'pay_at_venue' || (b.paymentMethod === 'cash' && b.paymentStatus !== 'paid') ? (
                        <button type="button" className="btn-warn !px-2.5 !py-1.5 !text-xs" onClick={() => confirmPay.mutate(b.id)}>تأكيد نقدي</button>
                      ) : null}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </div>
  );
}
