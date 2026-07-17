import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../lib/api';
import { EmptyBlock, ErrorBlock, LoadingBlock, Modal, PageHeader, StatusBadge } from '../components/ui';

export default function FieldsPage() {
  const qc = useQueryClient();
  const [edit, setEdit] = useState(null);
  const [form, setForm] = useState({ name: '', address: '', phone: '', pricePerHour: '' });
  const [msg, setMsg] = useState('');

  const fields = useQuery({ queryKey: ['admin-fields'], queryFn: api.fields });

  const toggle = useMutation({
    mutationFn: (id) => api.toggleField(id),
    onSuccess: () => {
      setMsg('تم تحديث حالة الملعب');
      qc.invalidateQueries({ queryKey: ['admin-fields'] });
      qc.invalidateQueries({ queryKey: ['admin-stats'] });
    },
    onError: (e) => setMsg(e.message),
  });

  const save = useMutation({
    mutationFn: () => {
      const body = {};
      if (form.name.trim()) body.name = form.name.trim();
      if (form.address.trim()) body.address = form.address.trim();
      if (form.phone.trim()) body.phone = form.phone.trim();
      if (form.pricePerHour !== '' && Number.isFinite(Number(form.pricePerHour))) {
        body.pricePerHour = Number(form.pricePerHour);
      }
      return api.updateField(edit.id, body);
    },
    onSuccess: () => {
      setMsg('تم حفظ تعديلات الملعب');
      setEdit(null);
      qc.invalidateQueries({ queryKey: ['admin-fields'] });
    },
    onError: (e) => setMsg(e.message),
  });

  const openEdit = (f) => {
    setEdit(f);
    setForm({
      name: f.name || '',
      address: f.address || '',
      phone: '',
      pricePerHour: '',
    });
  };

  return (
    <div>
      <PageHeader title="الملاعب" subtitle="تفعيل/إيقاف وتعديل بيانات الملاعب على المنصة" />
      {msg ? <div className="mb-4 rounded-xl bg-pitch-50 px-3 py-2 text-sm text-pitch-800">{msg}</div> : null}

      {fields.isLoading ? <LoadingBlock /> : null}
      {fields.isError ? <ErrorBlock error={fields.error} onRetry={fields.refetch} /> : null}
      {!fields.isLoading && !fields.data?.length ? <EmptyBlock title="لا توجد ملاعب" /> : null}

      {fields.data?.length ? (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {fields.data.map((f) => (
            <div key={f.id} className="panel p-5">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h3 className="font-bold text-pitch-950">{f.name}</h3>
                  <p className="mt-1 text-sm text-pitch-600">{f.address || 'بدون عنوان'}</p>
                  <p className="mt-2 text-xs text-pitch-500">المالك: {f.ownerName || f.ownerId}</p>
                </div>
                <StatusBadge status={f.isActive ? 'active' : 'blocked'} />
              </div>
              <div className="mt-4 flex flex-wrap gap-2">
                <button type="button" className="btn-ghost !text-xs" onClick={() => openEdit(f)}>تعديل</button>
                <button
                  type="button"
                  className={f.isActive ? 'btn-danger !text-xs' : 'btn-primary !text-xs'}
                  onClick={() => toggle.mutate(f.id)}
                >
                  {f.isActive ? 'إيقاف' : 'تفعيل'}
                </button>
              </div>
            </div>
          ))}
        </div>
      ) : null}

      {edit ? (
        <Modal title={`تعديل: ${edit.name}`} onClose={() => setEdit(null)}>
          <label className="label">اسم الملعب</label>
          <input className="input mb-3" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          <label className="label">العنوان</label>
          <input className="input mb-3" value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} />
          <label className="label">الهاتف</label>
          <input className="input mb-3" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
          <label className="label">سعر الساعة (د.ع)</label>
          <input className="input mb-4" type="number" value={form.pricePerHour} onChange={(e) => setForm({ ...form, pricePerHour: e.target.value })} />
          <button type="button" className="btn-primary w-full" disabled={save.isPending} onClick={() => save.mutate()}>
            {save.isPending ? 'جاري الحفظ...' : 'حفظ'}
          </button>
          <p className="mt-2 text-xs text-pitch-500">اترك الحقول الفارغة إن لم ترد تغيير الهاتف/السعر عبر طلب جزئي — يُرسل ما أدخلته فقط إن وُجد.</p>
        </Modal>
      ) : null}
    </div>
  );
}
