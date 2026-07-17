import { Link, useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { api, formatDate, formatMoney } from '../lib/api';
import { ErrorBlock, LoadingBlock, PageHeader, StatCard, StatusBadge } from '../components/ui';
import { useLocale } from '../context/LocaleContext';

export default function OwnerDetailPage() {
  const { ownerId } = useParams();
  const { t, locale } = useLocale();
  const money = (v) => formatMoney(v, locale);
  const date = (v) => formatDate(v, locale);
  const detail = useQuery({ queryKey: ['admin-owner', ownerId], queryFn: () => api.owner(ownerId) });

  if (detail.isLoading) return <LoadingBlock />;
  if (detail.isError) return <ErrorBlock error={detail.error} onRetry={detail.refetch} />;

  const { owner, dashboard, wallet, payments } = detail.data;
  const txs = wallet?.transactions || [];

  return (
    <div>
      <PageHeader
        title={owner.name}
        subtitle={`${owner.email} · ${owner.phone || t('owners.noPhone')}`}
        actions={<Link to="/owners" className="btn-ghost">{t('owners.back')}</Link>}
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label={t('owners.revenue')} value={money(dashboard.totalRevenue)} />
        <StatCard label={t('owners.commission')} value={money(dashboard.appCommission)} />
        <StatCard label={t('owners.net')} value={money(dashboard.netRevenue)} />
        <StatCard label={t('owners.balance')} value={money(wallet?.balance)} hint={wallet?.status} />
      </div>

      <div className="mt-4 grid gap-4 lg:grid-cols-2">
        <section className="panel overflow-hidden">
          <div className="border-b border-pitch-100 px-5 py-4 font-bold dark:border-pitch-800">{t('owners.ownerBookings')}</div>
          <div className="max-h-96 overflow-auto">
            <table className="min-w-full text-sm">
              <thead className="table-head">
                <tr>
                  <th className="px-3 py-2 text-start">{t('dash.field')}</th>
                  <th className="px-3 py-2 text-start">{t('dash.user')}</th>
                  <th className="px-3 py-2 text-start">{t('dash.status')}</th>
                  <th className="px-3 py-2 text-start">{t('dash.amount')}</th>
                </tr>
              </thead>
              <tbody>
                {(dashboard.bookings || []).map((b) => (
                  <tr key={b.id} className="table-row">
                    <td className="px-3 py-2">{b.fieldName}</td>
                    <td className="px-3 py-2">{b.userName}</td>
                    <td className="px-3 py-2"><StatusBadge status={b.status} /></td>
                    <td className="px-3 py-2">{money(b.totalPrice)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!dashboard.bookings?.length ? <p className="p-4 text-sm text-pitch-500">{t('owners.noBookings')}</p> : null}
          </div>
        </section>

        <section className="panel overflow-hidden">
          <div className="border-b border-pitch-100 px-5 py-4 font-bold dark:border-pitch-800">
            {t('owners.walletTx')}
            <span className="ms-2 text-xs font-normal text-pitch-500">{t('owners.due')}: {money(payments?.outstandingAmount)}</span>
          </div>
          <div className="max-h-96 overflow-auto">
            <table className="min-w-full text-sm">
              <thead className="table-head">
                <tr>
                  <th className="px-3 py-2 text-start">{t('owners.type')}</th>
                  <th className="px-3 py-2 text-start">{t('owners.amount')}</th>
                  <th className="px-3 py-2 text-start">{t('owners.desc')}</th>
                  <th className="px-3 py-2 text-start">{t('owners.date')}</th>
                </tr>
              </thead>
              <tbody>
                {txs.map((tx) => (
                  <tr key={tx.id} className="table-row">
                    <td className="px-3 py-2">{tx.typeLabel || tx.type}</td>
                    <td className={`px-3 py-2 font-semibold ${tx.amount >= 0 ? 'text-pitch-700 dark:text-pitch-300' : 'text-red-600'}`}>{money(tx.amount)}</td>
                    <td className="px-3 py-2">{tx.description}</td>
                    <td className="px-3 py-2 whitespace-nowrap">{date(tx.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!txs.length ? <p className="p-4 text-sm text-pitch-500">{t('owners.noTx')}</p> : null}
          </div>
        </section>
      </div>
    </div>
  );
}
