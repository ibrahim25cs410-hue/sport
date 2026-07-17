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

  const nowLabel = new Date().toLocaleString(locale === 'en' ? 'en-GB' : 'ar-IQ', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit',
  });

  const refreshAll = () => {
    stats.refetch(); financials.refetch(); pending.refetch();
    bookings.refetch(); fields.refetch(); owners.refetch();
  };

  return (
    <div className="space-y-5">
      <section className="overflow-hidden rounded-3xl border border-pitch-800/20 bg-pitch-950 text-white shadow-panel dark:border-pitch-700">
        <div className="relative px-5 py-6 lg:px-8 lg:py-7">
          <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(700px_280px_at_0%_0%,rgba(94,163,111,0.35),transparent_60%)]" />
          <div className="relative flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="text-xs font-semibold tracking-wide text-pitch-300">{t('dash.ops')}</p>
              <h1 className="mt-2 text-2xl font-bold tracking-tight lg:text-3xl">
                {t('dash.welcome')}{user?.name ? `، ${user.name}` : ''}
              </h1>
              <p className="mt-2 max-w-xl text-sm text-pitch-200/90">{t('dash.welcomeHint')}</p>
              <p className="mt-3 text-xs text-pitch-400">{nowLabel}</p>
            </div>
            <div className="flex flex-wrap gap-2">
              <button type="button" className="btn !bg-white/10 !text-white hover:!bg-white/20" onClick={refreshAll}>
                <RefreshCw className="h-4 w-4" /> {t('refresh')}
              </button>
              <Link to="/bookings?status=pending" className="btn !bg-amber-500 !text-white hover:!bg-amber-600">
                <AlertTriangle className="h-4 w-4" /> {t('dash.pending')} ({pendingList.length})
              </Link>
              <Link to="/bookings" className="btn !bg-pitch-600 !text-white hover:!bg-pitch-500">
                {t('dash.allBookings')} <ArrowUpRight className="h-4 w-4" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard icon={Users} label={t('dash.users')} value={s.totalUsers ?? 0} hint={t('dash.playersHint')} />
        <StatCard icon={Wallet} label={t('dash.owners')} value={s.totalOwners ?? 0} hint={blockedOwners ? t('dash.walletsBlocked', { n: blockedOwners }) : t('dash.walletsOk')} tone="info" />
        <StatCard icon={Building2} label={t('dash.fields')} value={s.totalFields ?? 0} hint={t('dash.fieldsHint', { a: activeFields, b: (s.totalFields || 0) - activeFields })} />
        <StatCard icon={CalendarDays} label={t('dash.bookings')} value={totalBookings} hint={t('dash.awaiting', { n: statusCounts.pending || 0 })} tone="warn" />
      </div>

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard icon={TrendingUp} label={t('dash.revenue')} value={money(totalRevenue)} hint={t('dash.revenueHint')} tone="money" />
        <StatCard icon={BadgeCheck} label={t('dash.commission')} value={money(commission)} tone="money" />
        <StatCard icon={Clock3} label={t('dash.paid')} value={paid} hint={t('dash.collection', { n: conversion })} />
        <StatCard icon={AlertTriangle} label={t('dash.needsAction')} value={pendingList.length} hint={t('dash.pendingNow')} tone="warn" />
      </div>

      <div className="grid gap-4 xl:grid-cols-12">
        <section className="panel p-5 xl:col-span-5">
          <div className="mb-4 flex items-center justify-between gap-2">
            <h2 className="font-bold text-pitch-950 dark:text-pitch-50">{t('dash.statusDist')}</h2>
            <span className="text-xs text-pitch-500">{t('dash.last100')}</span>
          </div>
          <DonutChart segments={statusSegments} />
        </section>
        <section className="panel p-5 xl:col-span-4">
          <h2 className="mb-4 font-bold text-pitch-950 dark:text-pitch-50">{t('dash.topFields')}</h2>
          {topFields.length ? <BarChart data={topFields} height={200} /> : <p className="py-10 text-center text-sm text-pitch-500">{t('dash.noChart')}</p>}
        </section>
        <section className="panel flex flex-col gap-4 p-5 xl:col-span-3">
          <h2 className="font-bold text-pitch-950 dark:text-pitch-50">{t('dash.health')}</h2>
          <ProgressBar label={t('dash.activeFields')} value={activeFields} max={Math.max(1, fieldList.length)} color="bg-pitch-600" />
          <ProgressBar label={t('dash.collectionRate')} value={paid} max={Math.max(1, totalBookings)} color="bg-emerald-600" />
          <ProgressBar label={t('dash.approvalRate')} value={statusCounts.approved || 0} max={Math.max(1, totalBookings)} color="bg-sky-600" />
          <div className="mt-auto rounded-xl bg-pitch-50 px-3 py-3 text-xs text-pitch-700 dark:bg-pitch-900 dark:text-pitch-200">
            <p className="font-semibold">{t('dash.ownerNet')}</p>
            <p className="mt-1 text-lg font-bold text-pitch-950 dark:text-pitch-50">{money(totalRevenue - commission)}</p>
          </div>
        </section>
      </div>

      <div className="grid gap-4 xl:grid-cols-12">
        <section className="panel overflow-hidden xl:col-span-8">
          <div className="flex items-center justify-between border-b border-pitch-100 px-5 py-4 dark:border-pitch-800">
            <div>
              <h2 className="font-bold text-pitch-950 dark:text-pitch-50">{t('dash.approvalQueue')}</h2>
              <p className="text-xs text-pitch-500">{t('dash.approvalHint')}</p>
            </div>
            <Link to="/bookings?status=pending" className="text-sm font-semibold text-pitch-700 hover:underline dark:text-pitch-300">{t('dash.viewAll')}</Link>
          </div>
          {!pendingList.length ? (
            <div className="px-5 py-12 text-center text-sm text-pitch-500">{t('dash.queueEmpty')}</div>
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
        </section>

        <section className="panel p-5 xl:col-span-4">
          <h2 className="mb-4 font-bold text-pitch-950 dark:text-pitch-50">{t('dash.shortcuts')}</h2>
          <div className="grid gap-2">
            {[
              { to: '/owners', title: t('dash.ownersLink'), desc: t('dash.ownersDesc') },
              { to: '/fields', title: t('dash.fieldsLink'), desc: t('dash.fieldsDesc') },
              { to: '/users', title: t('dash.usersLink'), desc: t('dash.usersDesc') },
              { to: '/bookings', title: t('dash.bookingsLink'), desc: t('dash.bookingsDesc') },
            ].map((item) => (
              <Link key={item.to} to={item.to} className="group flex items-center justify-between rounded-xl border border-pitch-100 bg-pitch-50/60 px-4 py-3 transition hover:border-pitch-300 hover:bg-white dark:border-pitch-800 dark:bg-pitch-900/50 dark:hover:bg-pitch-900">
                <div>
                  <p className="text-sm font-bold text-pitch-900 dark:text-pitch-50">{item.title}</p>
                  <p className="text-xs text-pitch-500">{item.desc}</p>
                </div>
                <ArrowUpRight className="h-4 w-4 text-pitch-400 group-hover:text-pitch-700 dark:group-hover:text-pitch-200" />
              </Link>
            ))}
          </div>
          <div className="mt-5 rounded-xl border border-dashed border-pitch-200 px-4 py-3 text-xs text-pitch-600 dark:border-pitch-700 dark:text-pitch-300">
            <p className="font-semibold text-pitch-800 dark:text-pitch-100">{t('dash.connection')}</p>
            <p className="mt-1">{t('dash.connectionHint')}</p>
          </div>
        </section>
      </div>

      <section className="panel overflow-hidden">
        <div className="flex items-center justify-between border-b border-pitch-100 px-5 py-4 dark:border-pitch-800">
          <h2 className="font-bold text-pitch-950 dark:text-pitch-50">{t('dash.latest')}</h2>
          <Link to="/bookings" className="text-sm font-semibold text-pitch-700 hover:underline dark:text-pitch-300">{t('dash.details')}</Link>
        </div>
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
      </section>
    </div>
  );
}
