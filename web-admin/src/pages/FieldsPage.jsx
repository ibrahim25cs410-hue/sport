import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../lib/api';
import { EmptyBlock, ErrorBlock, LoadingBlock, Modal, PageHeader, StatusBadge } from '../components/ui';
import { useLocale } from '../context/LocaleContext';
import { useAuth } from '../context/AuthContext';

export default function FieldsPage() {
  const { t } = useLocale();
  const { hasPermission } = useAuth();
  const canManage = hasPermission('fields.manage');
  const qc = useQueryClient();
  const [edit, setEdit] = useState(null);
  const [form, setForm] = useState({ name: '', address: '', phone: '', pricePerHour: '' });
  const [msg, setMsg] = useState('');
  const fields = useQuery({ queryKey: ['admin-fields'], queryFn: api.fields });

  const toggle = useMutation({
    mutationFn: (id) => api.toggleField(id),
    onSuccess: () => { setMsg(t('fields.toggled')); qc.invalidateQueries({ queryKey: ['admin-fields'] }); qc.invalidateQueries({ queryKey: ['admin-stats'] }); },
    onError: (e) => setMsg(e.message),
  });

  const save = useMutation({
    mutationFn: () => {
      const body = {};
      if (form.name.trim()) body.name = form.name.trim();
      if (form.address.trim()) body.address = form.address.trim();
      if (form.phone.trim()) body.phone = form.phone.trim();
      if (form.pricePerHour !== '' && Number.isFinite(Number(form.pricePerHour))) body.pricePerHour = Number(form.pricePerHour);
      return api.updateField(edit.id, body);
    },
    onSuccess: () => { setMsg(t('fields.saved')); setEdit(null); qc.invalidateQueries({ queryKey: ['admin-fields'] }); },
    onError: (e) => setMsg(e.message),
  });

  return (
    <div>
      <PageHeader title={t('fields.title')} subtitle={t('fields.subtitle')} />
      {msg ? <div className="mb-4 rounded-xl bg-pitch-50 px-3 py-2 text-sm dark:bg-pitch-900 dark:text-pitch-100">{msg}</div> : null}
      {fields.isLoading ? <LoadingBlock /> : null}
      {fields.isError ? <ErrorBlock error={fields.error} onRetry={fields.refetch} /> : null}
      {!fields.isLoading && !fields.data?.length ? <EmptyBlock title={t('fields.empty')} /> : null}

      {fields.data?.length ? (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {fields.data.map((f) => (
            <div key={f.id} className="panel p-5">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h3 className="font-bold text-pitch-950 dark:text-pitch-50">{f.name}</h3>
                  <p className="mt-1 text-sm text-pitch-600 dark:text-pitch-300">{f.address || t('fields.noAddress')}</p>
                  <p className="mt-2 text-xs text-pitch-500">{t('fields.owner')}: {f.ownerName || f.ownerId}</p>
                </div>
                <StatusBadge status={f.isActive ? 'active' : 'blocked'} />
              </div>
              {canManage ? <div className="mt-4 flex flex-wrap gap-2">
                <button type="button" className="btn-ghost !text-xs" onClick={() => { setEdit(f); setForm({ name: f.name || '', address: f.address || '', phone: '', pricePerHour: '' }); }}>{t('fields.edit')}</button>
                <button type="button" className={f.isActive ? 'btn-danger !text-xs' : 'btn-primary !text-xs'} onClick={() => toggle.mutate(f.id)}>
                  {f.isActive ? t('fields.disable') : t('fields.enable')}
                </button>
              </div> : null}
            </div>
          ))}
        </div>
      ) : null}

      {edit ? (
        <Modal title={`${t('fields.editTitle')}: ${edit.name}`} onClose={() => setEdit(null)}>
          <label className="label">{t('fields.name')}</label>
          <input className="input mb-3" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          <label className="label">{t('fields.address')}</label>
          <input className="input mb-3" value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} />
          <label className="label">{t('fields.phone')}</label>
          <input className="input mb-3" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
          <label className="label">{t('fields.price')}</label>
          <input className="input mb-4" type="number" value={form.pricePerHour} onChange={(e) => setForm({ ...form, pricePerHour: e.target.value })} />
          <button type="button" className="btn-primary w-full" disabled={save.isPending} onClick={() => save.mutate()}>
            {save.isPending ? t('saving') : t('save')}
          </button>
          <p className="mt-2 text-xs text-pitch-500">{t('fields.editHint')}</p>
        </Modal>
      ) : null}
    </div>
  );
}
