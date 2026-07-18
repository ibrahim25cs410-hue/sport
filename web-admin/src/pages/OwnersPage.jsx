import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api, formatMoney } from '../lib/api';
import { EmptyBlock, ErrorBlock, LoadingBlock, Modal, PageHeader, StatusBadge } from '../components/ui';
import { useLocale } from '../context/LocaleContext';
import { useAuth } from '../context/AuthContext';

export default function OwnersPage() {
  const { t, locale } = useLocale();
  const { hasPermission } = useAuth();
  const canManage = hasPermission('finance.manage');
  const qc = useQueryClient();
  const money = (v) => formatMoney(v, locale);
  const [topUp, setTopUp] = useState(null);
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [msg, setMsg] = useState('');
  const owners = useQuery({ queryKey: ['admin-owners'], queryFn: api.owners });

  const topUpMut = useMutation({
    mutationFn: () => api.topUp(topUp.id, Number(amount), note),
    onSuccess: () => {
      setMsg(t('owners.topped', { name: topUp.name }));
      setTopUp(null); setAmount(''); setNote('');
      qc.invalidateQueries({ queryKey: ['admin-owners'] });
    },
    onError: (e) => setMsg(e.message),
  });

  const blockMut = useMutation({
    mutationFn: ({ id, status }) => api.setWalletStatus(id, status),
    onSuccess: () => { setMsg(t('owners.walletUpdated')); qc.invalidateQueries({ queryKey: ['admin-owners'] }); },
    onError: (e) => setMsg(e.message),
  });

  return (
    <div>
      <PageHeader title={t('owners.title')} subtitle={t('owners.subtitle')} />
      {msg ? <div className="mb-4 rounded-xl bg-pitch-50 px-3 py-2 text-sm dark:bg-pitch-900 dark:text-pitch-100">{msg}</div> : null}
      {owners.isLoading ? <LoadingBlock /> : null}
      {owners.isError ? <ErrorBlock error={owners.error} onRetry={owners.refetch} /> : null}
      {!owners.isLoading && !owners.data?.length ? <EmptyBlock title={t('owners.empty')} /> : null}

      {owners.data?.length ? (
        <div className="panel overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="table-head">
              <tr>
                <th className="px-4 py-3 text-start">{t('owners.owner')}</th>
                <th className="px-4 py-3 text-start">{t('owners.contact')}</th>
                <th className="px-4 py-3 text-start">{t('owners.fields')}</th>
                <th className="px-4 py-3 text-start">{t('owners.wallet')}</th>
                <th className="px-4 py-3 text-start">{t('owners.status')}</th>
                <th className="px-4 py-3 text-start">{t('actions')}</th>
              </tr>
            </thead>
            <tbody>
              {owners.data.map((o) => (
                <tr key={o.id} className="table-row">
                  <td className="px-4 py-3 font-semibold">{o.name}</td>
                  <td className="px-4 py-3">
                    <div>{o.email}</div>
                    <div className="text-xs text-pitch-500">{o.phone || '—'}</div>
                  </td>
                  <td className="px-4 py-3">{o.fieldCount}</td>
                  <td className="px-4 py-3">{money(o.walletBalance)}</td>
                  <td className="px-4 py-3"><StatusBadge status={o.walletStatus || 'active'} /></td>
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-1.5">
                      <Link className="btn-ghost !px-2.5 !py-1.5 !text-xs" to={`/owners/${o.id}`}>{t('owners.details')}</Link>
                      {canManage ? <button type="button" className="btn-primary !px-2.5 !py-1.5 !text-xs" onClick={() => setTopUp(o)}>{t('owners.topUp')}</button> : null}
                      {canManage ? (
                      <button
                        type="button"
                        className={o.walletStatus === 'blocked' ? 'btn-primary !px-2.5 !py-1.5 !text-xs' : 'btn-danger !px-2.5 !py-1.5 !text-xs'}
                        onClick={() => blockMut.mutate({ id: o.id, status: o.walletStatus === 'blocked' ? 'active' : 'blocked' })}
                      >
                        {o.walletStatus === 'blocked' ? t('owners.enable') : t('owners.disable')}
                      </button>
                      ) : null}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}

      {topUp ? (
        <Modal title={t('owners.topUpTitle', { name: topUp.name })} onClose={() => setTopUp(null)}>
          <label className="label">{t('owners.amount')}</label>
          <input className="input mb-3" type="number" min="1000" value={amount} onChange={(e) => setAmount(e.target.value)} />
          <label className="label">{t('owners.note')}</label>
          <input className="input mb-4" value={note} onChange={(e) => setNote(e.target.value)} placeholder={t('owners.notePh')} />
          <button type="button" className="btn-primary w-full" disabled={topUpMut.isPending || !amount || Number(amount) <= 0} onClick={() => topUpMut.mutate()}>
            {topUpMut.isPending ? t('owners.topping') : t('owners.confirm')}
          </button>
        </Modal>
      ) : null}
    </div>
  );
}
