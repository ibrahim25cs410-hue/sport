import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api, formatMoney } from '../lib/api';
import { EmptyBlock, ErrorBlock, LoadingBlock, Modal, PageHeader, StatusBadge } from '../components/ui';

export default function OwnersPage() {
  const qc = useQueryClient();
  const [topUp, setTopUp] = useState(null);
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [msg, setMsg] = useState('');

  const owners = useQuery({ queryKey: ['admin-owners'], queryFn: api.owners });

  const topUpMut = useMutation({
    mutationFn: () => api.topUp(topUp.id, Number(amount), note),
    onSuccess: () => {
      setMsg(`تم شحن محفظة ${topUp.name}`);
      setTopUp(null);
      setAmount('');
      setNote('');
      qc.invalidateQueries({ queryKey: ['admin-owners'] });
    },
    onError: (e) => setMsg(e.message),
  });

  const blockMut = useMutation({
    mutationFn: ({ id, status }) => api.setWalletStatus(id, status),
    onSuccess: () => {
      setMsg('تم تحديث حالة المحفظة');
      qc.invalidateQueries({ queryKey: ['admin-owners'] });
    },
    onError: (e) => setMsg(e.message),
  });

  return (
    <div>
      <PageHeader title="الملاك" subtitle="محافظ الملاك، الشحن، والإيقاف — مربوط مباشرة بالمنصة" />
      {msg ? <div className="mb-4 rounded-xl bg-pitch-50 px-3 py-2 text-sm text-pitch-800">{msg}</div> : null}

      {owners.isLoading ? <LoadingBlock /> : null}
      {owners.isError ? <ErrorBlock error={owners.error} onRetry={owners.refetch} /> : null}
      {!owners.isLoading && !owners.data?.length ? <EmptyBlock title="لا يوجد ملاك" /> : null}

      {owners.data?.length ? (
        <div className="panel overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-pitch-50 text-pitch-700">
              <tr>
                <th className="px-4 py-3 text-right">المالك</th>
                <th className="px-4 py-3 text-right">التواصل</th>
                <th className="px-4 py-3 text-right">الملاعب</th>
                <th className="px-4 py-3 text-right">المحفظة</th>
                <th className="px-4 py-3 text-right">الحالة</th>
                <th className="px-4 py-3 text-right">إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {owners.data.map((o) => (
                <tr key={o.id} className="border-t border-pitch-100">
                  <td className="px-4 py-3 font-semibold">{o.name}</td>
                  <td className="px-4 py-3">
                    <div>{o.email}</div>
                    <div className="text-xs text-pitch-500">{o.phone || '—'}</div>
                  </td>
                  <td className="px-4 py-3">{o.fieldCount}</td>
                  <td className="px-4 py-3">{formatMoney(o.walletBalance)}</td>
                  <td className="px-4 py-3"><StatusBadge status={o.walletStatus || 'active'} /></td>
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-1.5">
                      <Link className="btn-ghost !px-2.5 !py-1.5 !text-xs" to={`/owners/${o.id}`}>تفاصيل</Link>
                      <button type="button" className="btn-primary !px-2.5 !py-1.5 !text-xs" onClick={() => setTopUp(o)}>شحن</button>
                      <button
                        type="button"
                        className={o.walletStatus === 'blocked' ? 'btn-primary !px-2.5 !py-1.5 !text-xs' : 'btn-danger !px-2.5 !py-1.5 !text-xs'}
                        onClick={() => blockMut.mutate({
                          id: o.id,
                          status: o.walletStatus === 'blocked' ? 'active' : 'blocked',
                        })}
                      >
                        {o.walletStatus === 'blocked' ? 'تفعيل' : 'إيقاف'}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}

      {topUp ? (
        <Modal title={`شحن محفظة ${topUp.name}`} onClose={() => setTopUp(null)}>
          <label className="label">المبلغ (د.ع)</label>
          <input className="input mb-3" type="number" min="1000" value={amount} onChange={(e) => setAmount(e.target.value)} />
          <label className="label">ملاحظة</label>
          <input className="input mb-4" value={note} onChange={(e) => setNote(e.target.value)} placeholder="مثلاً: شحن نقدي في المكتب" />
          <button
            type="button"
            className="btn-primary w-full"
            disabled={topUpMut.isPending || !amount || Number(amount) <= 0}
            onClick={() => topUpMut.mutate()}
          >
            {topUpMut.isPending ? 'جاري الشحن...' : 'تأكيد الشحن'}
          </button>
        </Modal>
      ) : null}
    </div>
  );
}
