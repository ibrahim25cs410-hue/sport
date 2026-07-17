import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSearchParams } from 'react-router-dom';
import { api, formatDate, formatMoney } from '../lib/api';
import { EmptyBlock, ErrorBlock, FilterChips, LoadingBlock, PageHeader, StatusBadge, Toolbar } from '../components/ui';
import { useLocale } from '../context/LocaleContext';

export default function BookingsPage() {
  const { t, locale } = useLocale();
  const [params, setParams] = useSearchParams();
  const status = params.get('status') || 'all';
  const [q, setQ] = useState('');
  const [msg, setMsg] = useState('');
  const qc = useQueryClient();
  const money = (v) => formatMoney(v, locale);
  const date = (v) => formatDate(v, locale);

  const query = useQuery({
    queryKey: ['admin-bookings', status, q],
    queryFn: () => api.bookings({ status, q, limit: 100 }),
  });

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ['admin-bookings'] });
    qc.invalidateQueries({ queryKey: ['admin-pending'] });
    qc.invalidateQueries({ queryKey: ['admin-stats'] });
    qc.invalidateQueries({ queryKey: ['admin-bookings-dash'] });
  };

  const approve = useMutation({ mutationFn: (id) => api.approveBooking(id), onSuccess: () => { setMsg(t('bookings.approved')); invalidate(); }, onError: (e) => setMsg(e.message) });
  const reject = useMutation({ mutationFn: (id) => api.rejectBooking(id), onSuccess: () => { setMsg(t('bookings.rejected')); invalidate(); }, onError: (e) => setMsg(e.message) });
  const cancel = useMutation({ mutationFn: (id) => api.cancelBooking(id), onSuccess: () => { setMsg(t('bookings.cancelled')); invalidate(); }, onError: (e) => setMsg(e.message) });
  const confirmPay = useMutation({ mutationFn: (id) => api.confirmCashPayment(id), onSuccess: () => { setMsg(t('bookings.cashOk')); invalidate(); }, onError: (e) => setMsg(e.message) });

  const items = useMemo(() => query.data?.items || [], [query.data]);
  const filters = [
    { id: 'all', label: t('bookings.filterAll') },
    { id: 'pending', label: t('bookings.filterPending') },
    { id: 'approved', label: t('bookings.filterApproved') },
    { id: 'rejected', label: t('bookings.filterRejected') },
    { id: 'cancelled', label: t('bookings.filterCancelled') },
  ];

  return (
    <div>
      <PageHeader title={t('bookings.title')} subtitle={t('bookings.subtitle')} />
      <Toolbar>
        <FilterChips
          options={filters}
          value={status}
          onChange={(id) => {
            const next = new URLSearchParams(params);
            if (id === 'all') next.delete('status');
            else next.set('status', id);
            setParams(next);
          }}
        />
        <input className="input max-w-sm" placeholder={t('bookings.searchPh')} value={q} onChange={(e) => setQ(e.target.value)} />
      </Toolbar>

      {msg ? <div className="mb-4 rounded-xl bg-pitch-50 px-3 py-2 text-sm text-pitch-800 dark:bg-pitch-900 dark:text-pitch-100">{msg}</div> : null}
      {query.isLoading ? <LoadingBlock /> : null}
      {query.isError ? <ErrorBlock error={query.error} onRetry={query.refetch} /> : null}
      {!query.isLoading && !query.isError && !items.length ? <EmptyBlock title={t('bookings.empty')} hint={t('bookings.emptyHint')} /> : null}

      {items.length ? (
        <div className="panel overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="table-head">
              <tr>
                <th className="px-3 py-3 text-start">#</th>
                <th className="px-3 py-3 text-start">{t('dash.field')}</th>
                <th className="px-3 py-3 text-start">{t('dash.user')}</th>
                <th className="px-3 py-3 text-start">{t('dash.time')}</th>
                <th className="px-3 py-3 text-start">{t('dash.amount')}</th>
                <th className="px-3 py-3 text-start">{t('dash.status')}</th>
                <th className="px-3 py-3 text-start">{t('dash.payment')}</th>
                <th className="px-3 py-3 text-start">{t('actions')}</th>
              </tr>
            </thead>
            <tbody>
              {items.map((b) => (
                <tr key={b.id} className="table-row align-top">
                  <td className="px-3 py-3 font-mono text-xs">{b.referenceCode || b.id}</td>
                  <td className="px-3 py-3 font-medium">{b.fieldName}</td>
                  <td className="px-3 py-3">
                    <div>{b.userName}</div>
                    <div className="text-xs text-pitch-500">{b.userPhone}</div>
                  </td>
                  <td className="px-3 py-3 whitespace-nowrap">
                    <div>{date(b.startTime)}</div>
                    <div className="text-xs text-pitch-500">{b.hours} {t('bookings.hours')}</div>
                  </td>
                  <td className="px-3 py-3 whitespace-nowrap">{money(b.totalPrice)}</td>
                  <td className="px-3 py-3"><StatusBadge status={b.status} /></td>
                  <td className="px-3 py-3"><StatusBadge status={b.paymentStatus} /></td>
                  <td className="px-3 py-3">
                    <div className="flex min-w-[180px] flex-wrap gap-1.5">
                      {b.status === 'pending' ? (
                        <>
                          <button type="button" className="btn-primary !px-2.5 !py-1.5 !text-xs" onClick={() => approve.mutate(b.id)}>{t('bookings.approve')}</button>
                          <button type="button" className="btn-danger !px-2.5 !py-1.5 !text-xs" onClick={() => reject.mutate(b.id)}>{t('bookings.reject')}</button>
                        </>
                      ) : null}
                      {(b.status === 'pending' || b.status === 'approved') ? (
                        <button type="button" className="btn-ghost !px-2.5 !py-1.5 !text-xs" onClick={() => cancel.mutate(b.id)}>{t('bookings.cancel')}</button>
                      ) : null}
                      {b.paymentStatus === 'pay_at_venue' || (b.paymentMethod === 'cash' && b.paymentStatus !== 'paid') ? (
                        <button type="button" className="btn-warn !px-2.5 !py-1.5 !text-xs" onClick={() => confirmPay.mutate(b.id)}>{t('bookings.confirmCash')}</button>
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
