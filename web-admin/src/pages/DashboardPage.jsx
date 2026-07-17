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
import { useLocale } from '../context/LocaleContext';

function Section({ title, action, children }) {
  return (
    <section className="space-y-3">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-sm font-bold tracking-wide text-pitch-700 dark:text-pitch-200">{title}</h2>
        {action || null}
      </div>
      {children}
    </section>
  );
}

export default function DashboardPage() {
  const { user } = useAuth();
  const { t, locale } = useLocale();
  const qc = useQueryClient();
  const money = (v) => formatMoney(v, locale);
  const date = (v) => formatDate(v, locale);

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
      const name = b.fieldName || '—';
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

  if (stats.isLoading || financials.isLoading || bookings.isLoading) return <LoadingBlock />;
  if (stats.isError) return <ErrorBlock error={stats.error} onRetry={stats.refetch} />;

  const s = stats.data || {};
  const f = financials.data || {};
  const pendingList = pending.data || [];
  const fieldList = fields.data || [];
  const ownerList = owners.data || [];
  const activeFields = fieldList.filter((x) => x.isActive).length;
  const blockedOwners = ownerList.filter((x) => x.walletStatus === 'blocked').length;
  const totalRevenue = Number(s.totalRevenueIqd) || 0;
  const commission = Number(s.platformCommissionIqd) || 0;
  const paid = Number(f.paidBookings ?? s.paidBookings) || 0;
  const totalBookings = Number(s.totalBookings) || 0;
  const conversion = totalBookings ? Math.round((paid / totalBookings) * 100) : 0;

  const statusSegments = [
    { label: t('dash.statusPending'), value: statusCounts.pending || 0, color: '#d97706' },
    { label: t('dash.statusApproved'), value: statusCounts.approved || 0, color: '#2d6a3e' },
    { label: t('dash.statusRejected'), value: statusCounts.rejected || 0, color: '#dc2626' },
    { label: t('dash.statusCancelled'), value: statusCounts.cancelled || 0, color: '#78716c' },
  ];

  const refreshAll = () => {
    stats.refetch(); financials.refetch(); pending.refetch();
    bookings.refetch(); fields.refetch(); owners.refetch();
  };

  return (
    <div className="space-y-8">
      {/* 1. Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs font-semibold text-pitch-500 dark:text-pitch-400">{t('dash.ops')}</p>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-pitch-950 dark:text-pitch-50">
            {t('dash.welcome')}{user?.name ? `، ${user.name}` : ''}
          </h1>
        </div>
        <div className="flex flex-wrap gap-2">
          <button type="button" className="btn-ghost" onClick={refreshAll}>
            <RefreshCw className="h-4 w-4" /> {t('refresh')}
          </button>
          <Link to="/bookings?status=pending" className="btn-warn">
            <AlertTriangle className="h-4 w-4" /> {t('dash.pending')} ({pendingList.length})
          </Link>
          <Link to="/bookings" className="btn-primary">
            {t('dash.allBookings')} <ArrowUpRight className="h-4 w-4" />
          </Link>
        </div>
      </div>

      {/* 2. Overview KPIs */}
      <Section title={t('section.overview')}>
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <StatCard icon={Users} label={t('dash.users')} value={s.totalUsers ?? 0} hint={t('dash.playersHint')} />
          <StatCard icon={Wallet} label={t('dash.owners')} value={s.totalOwners ?? 0} hint={blockedOwners ? t('dash.walletsBlocked', { n: blockedOwners }) : t('dash.walletsOk')} tone="info" />
          <StatCard icon={Building2} label={t('dash.fields')} value={s.totalFields ?? 0} hint={t('dash.fieldsHint', { a: activeFields, b: (s.totalFields || 0) - activeFields })} />
          <StatCard icon={CalendarDays} label={t('dash.bookings')} value={totalBookings} hint={t('dash.awaiting', { n: statusCounts.pending || 0 })} tone="warn" />
        </div>
      </Section>

      {/* 3. Finance KPIs */}
      <Section title={t('section.finance')}>
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <StatCard icon={TrendingUp} label={t('dash.revenue')} value={money(totalRevenue)} hint={t('dash.revenueHint')} tone="money" />
          <StatCard icon={BadgeCheck} label={t('dash.commission')} value={money(commission)} tone="money" />
          <StatCard icon={Clock3} label={t('dash.paid')} value={paid} hint={t('dash.collection', { n: conversion })} />
          <StatCard icon={AlertTriangle} label={t('dash.needsAction')} value={pendingList.length} hint={t('dash.pendingNow')} tone="warn" />
        </div>
      </Section>

      {/* 4. Action queue first */}
      <Section
        title={t('section.action')}
        action={<Link to="/bookings?status=pending" className="text-sm font-semibold text-pitch-700 hover:underline dark:text-pitch-300">{t('dash.viewAll')}</Link>}
      >
        <div className="panel overflow-hidden">
          <div className="border-b border-pitch-100 px-5 py-3 dark:border-pitch-800">
            <p className="text-xs text-pitch-500">{t('dash.approvalHint')}</p>
          </div>
          {!pendingList.length ? (
            <div className="px-5 py-10 text-center text-sm text-pitch-500">{t('dash.queueEmpty')}</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full text-sm">
                <thead className="table-head">
                  <tr>
                    <th className="px-4 py-3 text-start font-semibold">{t('dash.field')}</th>
                    <th className="px-4 py-3 text-start font-semibold">{t('dash.user')}</th>
                    <th className="px-4 py-3 text-start font-semibold">{t('dash.time')}</th>
                    <th className="px-4 py-3 text-start font-semibold">{t('dash.amount')}</th>
                    <th className="px-4 py-3 text-start font-semibold">{t('actions')}</th>
                  </tr>
                </thead>
                <tbody>
                  {pendingList.slice(0, 8).map((b) => (
                    <tr key={b.id} className="table-row hover:bg-pitch-50/50 dark:hover:bg-pitch-900/40">
                      <td className="px-4 py-3 font-medium">{b.fieldName}</td>
                      <td className="px-4 py-3">{b.userName}</td>
                      <td className="px-4 py-3 whitespace-nowrap">{date(b.startTime)}</td>
                      <td className="px-4 py-3 whitespace-nowrap font-semibold">{money(b.totalPrice)}</td>
                      <td className="px-4 py-3">
                        <div className="flex flex-wrap gap-1.5">
                          <button type="button" className="btn-primary !px-2.5 !py-1.5 !text-xs" disabled={approve.isPending} onClick={() => approve.mutate(b.id)}>{t('dash.approve')}</button>
                          <button type="button" className="btn-danger !px-2.5 !py-1.5 !text-xs" disabled={reject.isPending} onClick={() => reject.mutate(b.id)}>{t('dash.reject')}</button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </Section>

      {/* 5. Analytics */}
      <Section title={t('section.analytics')}>
        <div className="grid gap-4 xl:grid-cols-12">
          <div className="panel p-5 xl:col-span-5">
            <div className="mb-4 flex items-center justify-between gap-2">
              <h3 className="font-bold text-pitch-950 dark:text-pitch-50">{t('dash.statusDist')}</h3>
              <span className="text-xs text-pitch-500">{t('dash.last100')}</span>
            </div>
            <DonutChart segments={statusSegments} />
          </div>
          <div className="panel p-5 xl:col-span-4">
            <h3 className="mb-4 font-bold text-pitch-950 dark:text-pitch-50">{t('dash.topFields')}</h3>
            {topFields.length ? <BarChart data={topFields} height={200} /> : <p className="py-10 text-center text-sm text-pitch-500">{t('dash.noChart')}</p>}
          </div>
          <div className="panel flex flex-col gap-4 p-5 xl:col-span-3">
            <h3 className="font-bold text-pitch-950 dark:text-pitch-50">{t('dash.health')}</h3>
            <ProgressBar label={t('dash.activeFields')} value={activeFields} max={Math.max(1, fieldList.length)} color="bg-pitch-600" />
            <ProgressBar label={t('dash.collectionRate')} value={paid} max={Math.max(1, totalBookings)} color="bg-emerald-600" />
            <ProgressBar label={t('dash.approvalRate')} value={statusCounts.approved || 0} max={Math.max(1, totalBookings)} color="bg-sky-600" />
            <div className="mt-auto rounded-xl bg-pitch-50 px-3 py-3 text-xs text-pitch-700 dark:bg-pitch-900 dark:text-pitch-200">
              <p className="font-semibold">{t('dash.ownerNet')}</p>
              <p className="mt-1 text-lg font-bold text-pitch-950 dark:text-pitch-50">{money(totalRevenue - commission)}</p>
            </div>
          </div>
        </div>
      </Section>

      {/* 6. Recent activity */}
      <Section
        title={t('section.recent')}
        action={<Link to="/bookings" className="text-sm font-semibold text-pitch-700 hover:underline dark:text-pitch-300">{t('dash.details')}</Link>}
      >
        <div className="panel overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="table-head">
                <tr>
                  <th className="px-4 py-3 text-start">{t('dash.ref')}</th>
                  <th className="px-4 py-3 text-start">{t('dash.field')}</th>
                  <th className="px-4 py-3 text-start">{t('dash.user')}</th>
                  <th className="px-4 py-3 text-start">{t('dash.time')}</th>
                  <th className="px-4 py-3 text-start">{t('dash.status')}</th>
                  <th className="px-4 py-3 text-start">{t('dash.payment')}</th>
                  <th className="px-4 py-3 text-start">{t('dash.amount')}</th>
                </tr>
              </thead>
              <tbody>
                {allBookings.slice(0, 10).map((b) => (
                  <tr key={b.id} className="table-row">
                    <td className="px-4 py-3 font-mono text-xs">{b.referenceCode || b.id}</td>
                    <td className="px-4 py-3 font-medium">{b.fieldName}</td>
                    <td className="px-4 py-3">{b.userName}</td>
                    <td className="px-4 py-3 whitespace-nowrap">{date(b.startTime)}</td>
                    <td className="px-4 py-3"><StatusBadge status={b.status} /></td>
                    <td className="px-4 py-3"><StatusBadge status={b.paymentStatus} /></td>
                    <td className="px-4 py-3 font-semibold">{money(b.totalPrice)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!allBookings.length ? <p className="px-5 py-8 text-center text-sm text-pitch-500">{t('dash.noBookings')}</p> : null}
          </div>
        </div>
      </Section>
    </div>
  );
}
