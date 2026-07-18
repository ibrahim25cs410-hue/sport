import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, CalendarClock, Save, Search, Trash2, UserRound, Wrench } from 'lucide-react';
import { api, formatDate, formatMoney } from '../lib/api';
import { ErrorBlock, LoadingBlock, PageHeader, StatusBadge } from '../components/ui';
import { useLocale } from '../context/LocaleContext';
import { useFeedback } from '../context/FeedbackContext';

function copy(locale) {
  return locale === 'ar' ? {
    back: 'رجوع', createTitle: 'إنشاء حجز يدوي', createSub: 'أنشئ حجزاً نيابة عن العميل مع تحقق التوفر من الخادم',
    detail: 'تفاصيل الحجز', customer: 'العميل', field: 'الملعب', date: 'التاريخ', start: 'وقت البدء', hours: 'الساعات',
    payment: 'طريقة الدفع', notes: 'ملاحظات داخلية', create: 'إنشاء الحجز', reschedule: 'إعادة الجدولة', save: 'حفظ الموعد الجديد',
    maintenance: 'حظر صيانة', maintenanceSub: 'امنع الحجوزات أثناء الصيانة أو الإغلاق التشغيلي', reason: 'السبب',
    end: 'وقت الانتهاء', block: 'إنشاء الحظر', existing: 'فترات الصيانة القادمة', empty: 'لا توجد فترات صيانة',
    summary: 'ملخص', timeline: 'سجل الحالة', amount: 'المبلغ', reference: 'المرجع',
  } : {
    back: 'Back', createTitle: 'Create manual booking', createSub: 'Book on behalf of a customer with server-side availability validation',
    detail: 'Booking details', customer: 'Customer', field: 'Field', date: 'Date', start: 'Start time', hours: 'Hours',
    payment: 'Payment method', notes: 'Internal notes', create: 'Create booking', reschedule: 'Reschedule', save: 'Save new time',
    maintenance: 'Maintenance block', maintenanceSub: 'Prevent bookings during maintenance or operational closures', reason: 'Reason',
    end: 'End time', block: 'Create block', existing: 'Upcoming maintenance', empty: 'No maintenance blocks',
    summary: 'Summary', timeline: 'Status history', amount: 'Amount', reference: 'Reference',
  };
}

function FormField({ label, children }) {
  return <label className="block"><span className="label">{label}</span>{children}</label>;
}

export function BookingCreatePage() {
  const { locale } = useLocale();
  const c = copy(locale);
  const { notify } = useFeedback();
  const navigate = useNavigate();
  const fields = useQuery({ queryKey: ['admin-fields'], queryFn: api.fields });
  const [userSearch, setUserSearch] = useState('');
  const users = useQuery({
    queryKey: ['admin-users-picker', userSearch],
    queryFn: () => api.users({ q: userSearch, limit: 12 }),
    enabled: userSearch.trim().length >= 2,
  });
  const [form, setForm] = useState({ userId: '', fieldId: '', date: '', startTime: '', hours: 1, paymentMethod: 'cash', notes: '' });
  const set = (key) => (e) => setForm((v) => ({ ...v, [key]: e.target.value }));
  const mutation = useMutation({
    mutationFn: () => api.createBooking({ ...form, hours: Number(form.hours), startTime: new Date(`${form.date}T${form.startTime}`).toISOString(), source: 'admin' }),
    onSuccess: (data) => { notify(locale === 'ar' ? 'تم إنشاء الحجز' : 'Booking created'); navigate(`/bookings/${data.id || data.booking?.id}`); },
    onError: (e) => notify(e.message, 'error'),
  });
  const userItems = users.data?.items || [];
  return (
    <div>
      <PageHeader title={c.createTitle} subtitle={c.createSub} actions={<Link className="btn-ghost" to="/bookings"><ArrowLeft className="h-4 w-4" />{c.back}</Link>} />
      <form className="panel mx-auto max-w-3xl p-5" onSubmit={(e) => { e.preventDefault(); mutation.mutate(); }}>
        <div className="grid gap-4 sm:grid-cols-2">
          <FormField label={c.customer}>
            <div className="relative">
              <Search className="absolute start-3 top-3 h-4 w-4 text-pitch-500" />
              <input className="input ps-9" value={userSearch} onChange={(e) => { setUserSearch(e.target.value); setForm((v) => ({ ...v, userId: '' })); }} placeholder={locale === 'ar' ? 'ابحث بالاسم أو الهاتف أو البريد' : 'Search name, phone, or email'} />
              {userSearch.length >= 2 && !form.userId ? <div className="absolute z-30 mt-1 max-h-52 w-full overflow-y-auto rounded-xl border border-pitch-200 bg-white p-1 shadow-xl dark:border-pitch-700 dark:bg-pitch-950">{users.isLoading ? <p className="p-3 text-sm text-pitch-500">{locale === 'ar' ? 'جاري البحث...' : 'Searching...'}</p> : userItems.map((user) => <button type="button" key={user.id} className="flex w-full items-center gap-3 rounded-lg p-2 text-start hover:bg-pitch-50 dark:hover:bg-pitch-900" onClick={() => { setForm((v) => ({ ...v, userId: user.id })); setUserSearch(user.name); }}><UserRound className="h-4 w-4" /><span><strong className="block text-sm">{user.name}</strong><small className="text-pitch-500">{user.phone || user.email}</small></span></button>)}</div> : null}
            </div>
            {form.userId ? <p className="mt-1 text-xs font-semibold text-emerald-700">{locale === 'ar' ? 'تم اختيار المستخدم' : 'User selected'}</p> : null}
          </FormField>
          <FormField label={c.field}><select required className="input" value={form.fieldId} onChange={set('fieldId')}><option value="">—</option>{(fields.data || []).filter((x) => x.isActive !== false).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</select></FormField>
          <FormField label={c.date}><input required min={new Date().toISOString().slice(0, 10)} type="date" className="input" value={form.date} onChange={set('date')} /></FormField>
          <FormField label={c.start}><input required type="time" className="input" value={form.startTime} onChange={set('startTime')} /></FormField>
          <FormField label={c.hours}><input required min="1" max="12" type="number" className="input" value={form.hours} onChange={set('hours')} /></FormField>
          <FormField label={c.payment}><select className="input" value={form.paymentMethod} onChange={set('paymentMethod')}><option value="cash">{locale === 'ar' ? 'نقداً في الملعب' : 'Cash at venue'}</option></select><p className="mt-1 text-xs text-pitch-500">{locale === 'ar' ? 'الدفع نقداً في الملعب فقط' : 'Cash payment at the venue only'}</p></FormField>
        </div>
        <FormField label={c.notes}><textarea className="input mt-4 min-h-24" value={form.notes} onChange={set('notes')} /></FormField>
        <div className="mt-5 flex justify-end"><button className="btn-primary" disabled={mutation.isPending || !form.userId}><Save className="h-4 w-4" />{mutation.isPending ? '…' : c.create}</button></div>
      </form>
    </div>
  );
}

export function BookingDetailPage() {
  const { bookingId } = useParams();
  const { locale } = useLocale();
  const c = copy(locale);
  const query = useQuery({ queryKey: ['admin-booking', bookingId], queryFn: () => api.booking(bookingId) });
  if (query.isLoading) return <LoadingBlock />;
  if (query.isError) return <ErrorBlock error={query.error} onRetry={query.refetch} />;
  const b = query.data?.booking || query.data;
  return <div><PageHeader title={c.detail} subtitle={`${c.reference}: ${b.referenceCode || b.id}`} actions={<><Link className="btn-ghost" to="/bookings">{c.back}</Link><Link className="btn-primary" to={`/bookings/${bookingId}/reschedule`}><CalendarClock className="h-4 w-4" />{c.reschedule}</Link></>} /><div className="grid gap-5 lg:grid-cols-[1fr_360px]"><div className="panel p-5"><div className="mb-5 flex items-center justify-between"><StatusBadge status={b.status} /><StatusBadge status={b.paymentStatus} /></div><dl className="grid gap-4 sm:grid-cols-2">{[[c.customer,b.userName],[c.field,b.fieldName],[c.start,formatDate(b.startTime,locale)],[c.hours,b.hours],[c.amount,formatMoney(b.totalPrice,locale)],[c.payment,b.paymentMethod]].map(([k,v]) => <div className="rounded-xl bg-pitch-50 p-3 dark:bg-pitch-900" key={k}><dt className="text-xs text-pitch-500">{k}</dt><dd className="mt-1 font-bold">{v || '—'}</dd></div>)}</dl>{b.notes ? <div className="mt-4 rounded-xl border border-pitch-100 p-4 dark:border-pitch-800"><p className="text-xs text-pitch-500">{c.notes}</p><p className="mt-1">{b.notes}</p></div> : null}</div><aside className="panel p-5"><h2 className="mb-4 font-bold">{c.timeline}</h2><ol className="space-y-4">{(b.history || []).map((event, i) => <li className="relative border-s-2 border-pitch-200 ps-4 dark:border-pitch-700" key={event.id || i}><span className="absolute -start-[5px] top-1 h-2 w-2 rounded-full bg-pitch-600" /><p className="font-semibold">{event.label || event.action}</p><p className="text-xs text-pitch-500">{formatDate(event.createdAt,locale)} · {event.actorName}</p></li>)}</ol></aside></div></div>;
}

export function BookingReschedulePage() {
  const { bookingId } = useParams();
  const { locale } = useLocale();
  const c = copy(locale);
  const { notify } = useFeedback();
  const navigate = useNavigate();
  const detail = useQuery({ queryKey: ['admin-booking', bookingId], queryFn: () => api.booking(bookingId) });
  const b = detail.data?.booking || detail.data;
  const [form, setForm] = useState({ date: '', startTime: '', reason: '' });
  const mutation = useMutation({ mutationFn: () => api.rescheduleBooking(bookingId, { startTime: new Date(`${form.date}T${form.startTime}`).toISOString(), reason: form.reason }), onSuccess: () => { notify(locale === 'ar' ? 'تمت إعادة الجدولة' : 'Booking rescheduled'); navigate(`/bookings/${bookingId}`); }, onError: (e) => notify(e.message, 'error') });
  if (detail.isLoading) return <LoadingBlock />;
  if (detail.isError) return <ErrorBlock error={detail.error} />;
  return <div><PageHeader title={c.reschedule} subtitle={`${b.fieldName} · ${formatDate(b.startTime,locale)}`} /><form className="panel mx-auto max-w-xl space-y-4 p-5" onSubmit={(e) => { e.preventDefault(); mutation.mutate(); }}><FormField label={c.date}><input required min={new Date().toISOString().slice(0,10)} type="date" className="input" value={form.date} onChange={(e) => setForm({...form,date:e.target.value})} /></FormField><FormField label={c.start}><input required type="time" className="input" value={form.startTime} onChange={(e) => setForm({...form,startTime:e.target.value})} /></FormField><FormField label={c.reason}><textarea required className="input min-h-24" value={form.reason} onChange={(e) => setForm({...form,reason:e.target.value})} /></FormField><button disabled={mutation.isPending} className="btn-primary w-full"><CalendarClock className="h-4 w-4" />{c.save}</button></form></div>;
}

export function MaintenancePage() {
  const { locale } = useLocale();
  const c = copy(locale);
  const { notify } = useFeedback();
  const qc = useQueryClient();
  const fields = useQuery({ queryKey: ['admin-fields'], queryFn: api.fields });
  const blocks = useQuery({ queryKey: ['admin-maintenance'], queryFn: () => api.maintenance({ upcoming: true }) });
  const [form, setForm] = useState({ fieldId: '', startTime: '', endTime: '', reason: '' });
  const create = useMutation({ mutationFn: () => api.createMaintenance(form), onSuccess: () => { notify(locale === 'ar' ? 'تم إنشاء فترة الصيانة' : 'Maintenance block created'); setForm({ fieldId:'',startTime:'',endTime:'',reason:'' }); qc.invalidateQueries({ queryKey: ['admin-maintenance'] }); }, onError: (e) => notify(e.message,'error') });
  const remove = useMutation({ mutationFn: api.deleteMaintenance, onSuccess: () => { notify(locale === 'ar' ? 'تم حذف الفترة' : 'Block removed'); qc.invalidateQueries({ queryKey: ['admin-maintenance'] }); } });
  const list = blocks.data?.items || [];
  return <div><PageHeader title={c.maintenance} subtitle={c.maintenanceSub} /><div className="grid gap-5 lg:grid-cols-[420px_1fr]"><form className="panel space-y-4 p-5" onSubmit={(e) => { e.preventDefault(); create.mutate(); }}><FormField label={c.field}><select required className="input" value={form.fieldId} onChange={(e) => setForm({...form,fieldId:e.target.value})}><option value="">—</option>{(fields.data || []).map((f) => <option value={f.id} key={f.id}>{f.name}</option>)}</select></FormField><FormField label={c.start}><input required type="datetime-local" className="input" value={form.startTime} onChange={(e) => setForm({...form,startTime:e.target.value})} /></FormField><FormField label={c.end}><input required type="datetime-local" className="input" value={form.endTime} onChange={(e) => setForm({...form,endTime:e.target.value})} /></FormField><FormField label={c.reason}><textarea required className="input min-h-20" value={form.reason} onChange={(e) => setForm({...form,reason:e.target.value})} /></FormField><button className="btn-warn w-full" disabled={create.isPending}><Wrench className="h-4 w-4" />{c.block}</button></form><div><h2 className="mb-3 font-bold">{c.existing}</h2>{blocks.isLoading ? <LoadingBlock /> : !list.length ? <div className="panel p-8 text-center text-pitch-500">{c.empty}</div> : <div className="space-y-2">{list.map((x) => <div className="panel flex items-center gap-3 p-4" key={x.id}><Wrench className="h-5 w-5 text-amber-600" /><div className="flex-1"><p className="font-bold">{x.fieldName}</p><p className="text-xs text-pitch-500">{formatDate(x.startTime,locale)} — {formatDate(x.endTime,locale)}</p><p className="mt-1 text-sm">{x.reason}</p></div><button className="btn-danger !px-2" onClick={() => remove.mutate(x.id)}><Trash2 className="h-4 w-4" /></button></div>)}</div>}</div></div></div>;
}
