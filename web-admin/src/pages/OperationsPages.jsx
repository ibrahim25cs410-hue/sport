import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { AlertTriangle, Bell, Check, ChevronLeft, ChevronRight, Download, Eye, FileBarChart, Plus, RefreshCw, Search, ShieldCheck, WalletCards } from 'lucide-react';
import { api, formatDate, formatMoney } from '../lib/api';
import { DateRangeControls } from '../components/AdminTools';
import { EmptyBlock, ErrorBlock, LoadingBlock, Modal, PageHeader, StatusBadge, Toolbar } from '../components/ui';
import { useLocale } from '../context/LocaleContext';
import { useFeedback } from '../context/FeedbackContext';

function useCopy(ar, en) {
  return useLocale().locale === 'ar' ? ar : en;
}

function initialRange(days = 30) {
  const to = new Date();
  const from = new Date();
  from.setDate(from.getDate() - days + 1);
  return { from: from.toISOString().slice(0, 10), to: to.toISOString().slice(0, 10) };
}

function QueryState({ query, empty, children }) {
  if (query.isLoading) return <LoadingBlock />;
  if (query.isError) return <ErrorBlock error={query.error} onRetry={query.refetch} />;
  if (!query.data?.items?.length) return <EmptyBlock title={empty} />;
  return children(query.data.items);
}

export function CalendarPage() {
  const { locale } = useLocale();
  const c = useCopy(
    { title: 'تقويم التشغيل', subtitle: 'جدول الحجوزات والصيانة عبر جميع الملاعب', today: 'اليوم', field: 'كل الملاعب', empty: 'لا توجد حجوزات في هذا النطاق', maintenance: 'صيانة', booking: 'حجز' },
    { title: 'Operations calendar', subtitle: 'Bookings and maintenance across every field', today: 'Today', field: 'All fields', empty: 'No bookings in this range', maintenance: 'Maintenance', booking: 'Booking' },
  );
  const [cursor, setCursor] = useState(() => new Date());
  const [fieldId, setFieldId] = useState('');
  const start = new Date(cursor.getFullYear(), cursor.getMonth(), 1);
  const end = new Date(cursor.getFullYear(), cursor.getMonth() + 1, 0);
  const query = useQuery({ queryKey: ['admin-calendar', start.toISOString(), fieldId], queryFn: () => api.calendar({ from: start.toISOString(), to: end.toISOString(), fieldId }) });
  const fields = useQuery({ queryKey: ['admin-fields'], queryFn: api.fields });
  const days = useMemo(() => {
    const cells = Array(start.getDay()).fill(null);
    for (let day = 1; day <= end.getDate(); day += 1) cells.push(new Date(cursor.getFullYear(), cursor.getMonth(), day));
    while (cells.length % 7) cells.push(null);
    return cells;
  }, [cursor]);
  const items = query.data?.items || [];
  return (
    <div>
      <PageHeader title={c.title} subtitle={c.subtitle} actions={<a className="btn-primary" href="/panel/bookings/new"><Plus className="h-4 w-4" />{locale === 'ar' ? 'حجز يدوي' : 'Manual booking'}</a>} />
      <Toolbar>
        <div className="flex items-center gap-2"><button className="btn-ghost !px-2" onClick={() => setCursor(new Date(cursor.getFullYear(), cursor.getMonth() - 1, 1))}><ChevronRight className="h-4 w-4" /></button><strong className="min-w-36 text-center">{cursor.toLocaleDateString(locale === 'ar' ? 'ar-IQ' : 'en-GB', { month: 'long', year: 'numeric' })}</strong><button className="btn-ghost !px-2" onClick={() => setCursor(new Date(cursor.getFullYear(), cursor.getMonth() + 1, 1))}><ChevronLeft className="h-4 w-4" /></button><button className="btn-ghost !py-2" onClick={() => setCursor(new Date())}>{c.today}</button></div>
        <select className="input max-w-xs" value={fieldId} onChange={(e) => setFieldId(e.target.value)}><option value="">{c.field}</option>{(fields.data || []).map((f) => <option key={f.id} value={f.id}>{f.name}</option>)}</select>
      </Toolbar>
      {query.isError ? <ErrorBlock error={query.error} onRetry={query.refetch} /> : (
        <div className="panel overflow-hidden">
          <div className="grid grid-cols-7 border-b border-pitch-200 bg-pitch-50 text-center text-xs font-bold dark:border-pitch-800 dark:bg-pitch-900">{['Sun','Mon','Tue','Wed','Thu','Fri','Sat'].map((d) => <div key={d} className="p-2">{d}</div>)}</div>
          <div className="grid grid-cols-7">{days.map((day, index) => {
            const dateKey = day?.toISOString().slice(0, 10);
            const dayItems = items.filter((item) => String(item.startTime || item.start).slice(0, 10) === dateKey);
            return <div key={`${dateKey}-${index}`} className="min-h-28 border-b border-e border-pitch-100 p-1.5 dark:border-pitch-800"><span className={`inline-flex h-7 w-7 items-center justify-center rounded-full text-xs ${dateKey === new Date().toISOString().slice(0, 10) ? 'bg-pitch-700 text-white' : ''}`}>{day?.getDate()}</span>{dayItems.slice(0, 3).map((item) => <a href={item.type === 'maintenance' ? '/panel/calendar' : `/panel/bookings/${item.id}`} key={item.id} className={`mt-1 block truncate rounded-md px-1.5 py-1 text-[10px] font-semibold ${item.type === 'maintenance' ? 'bg-amber-100 text-amber-900 dark:bg-amber-950 dark:text-amber-200' : 'bg-pitch-100 text-pitch-900 dark:bg-pitch-900 dark:text-pitch-100'}`}>{item.title || item.fieldName || (item.type === 'maintenance' ? c.maintenance : c.booking)}</a>)}</div>;
          })}</div>
        </div>
      )}
    </div>
  );
}

export function AlertsPage() {
  const { locale } = useLocale();
  const { notify } = useFeedback();
  const qc = useQueryClient();
  const c = useCopy(
    { title: 'مركز الإشعارات', subtitle: 'تنبيهات تشغيلية ومالية وأمنية قابلة للتنفيذ', markAll: 'تعليم الكل كمقروء', empty: 'لا توجد إشعارات', unread: 'غير مقروء', all: 'الكل' },
    { title: 'Notification center', subtitle: 'Actionable operational, financial, and security alerts', markAll: 'Mark all read', empty: 'No notifications', unread: 'Unread', all: 'All' },
  );
  const [filter, setFilter] = useState('all');
  const query = useQuery({ queryKey: ['admin-alerts', filter], queryFn: () => api.alerts({ unread: filter === 'unread' ? true : undefined }) });
  const done = () => { qc.invalidateQueries({ queryKey: ['admin-alerts'] }); notify(locale === 'ar' ? 'تم تحديث الإشعارات' : 'Notifications updated'); };
  const read = useMutation({ mutationFn: api.markAlertRead, onSuccess: done });
  const all = useMutation({ mutationFn: api.markAllAlertsRead, onSuccess: done });
  return <div><PageHeader title={c.title} subtitle={c.subtitle} actions={<button className="btn-ghost" disabled={all.isPending} onClick={() => all.mutate()}><Check className="h-4 w-4" />{c.markAll}</button>} /><Toolbar><div className="flex gap-2">{['all','unread'].map((x) => <button key={x} className={filter === x ? 'btn-primary !py-2' : 'btn-ghost !py-2'} onClick={() => setFilter(x)}>{c[x]}</button>)}</div><button className="btn-ghost !py-2" onClick={() => query.refetch()}><RefreshCw className="h-4 w-4" /></button></Toolbar><QueryState query={query} empty={c.empty}>{(items) => <div className="space-y-2">{items.map((item) => <article key={item.id} className={`panel flex gap-3 p-4 ${!item.readAt ? 'border-s-pitch-600 border-s-4' : ''}`}><div className={`mt-1 rounded-xl p-2 ${item.severity === 'critical' ? 'bg-red-100 text-red-700' : item.severity === 'warning' ? 'bg-amber-100 text-amber-700' : 'bg-pitch-100 text-pitch-700'}`}>{item.severity === 'warning' ? <AlertTriangle className="h-5 w-5" /> : <Bell className="h-5 w-5" />}</div><div className="min-w-0 flex-1"><div className="flex justify-between gap-2"><h3 className="font-bold">{item.title}</h3><time className="whitespace-nowrap text-xs text-pitch-500">{formatDate(item.createdAt, locale)}</time></div><p className="mt-1 text-sm text-pitch-600 dark:text-pitch-300">{item.message}</p>{item.actionUrl ? <a href={`/panel${item.actionUrl}`} className="mt-2 inline-flex text-xs font-bold text-pitch-700 underline dark:text-pitch-300">{locale === 'ar' ? 'عرض التفاصيل' : 'View details'}</a> : null}</div>{!item.readAt ? <button className="btn-ghost self-center !px-2" title={c.markAll} onClick={() => read.mutate(item.id)}><Check className="h-4 w-4" /></button> : null}</article>)}</div>}</QueryState></div>;
}

export function ReportsPage() {
  const { locale } = useLocale();
  const { notify } = useFeedback();
  const [range, setRange] = useState(initialRange());
  const [type, setType] = useState('revenue');
  const c = useCopy(
    { title: 'التقارير', subtitle: 'تحليل الإيرادات والحجوزات والإشغال مع تصدير منظم', generate: 'إنشاء تصدير', revenue: 'الإيرادات', bookings: 'الحجوزات', occupancy: 'الإشغال', empty: 'لا توجد بيانات للفترة' },
    { title: 'Reports', subtitle: 'Revenue, booking, and occupancy analysis with structured exports', generate: 'Create export', revenue: 'Revenue', bookings: 'Bookings', occupancy: 'Occupancy', empty: 'No data for this period' },
  );
  const query = useQuery({ queryKey: ['admin-reports', type, range], queryFn: () => api.reports({ type, ...range }) });
  const exporting = useMutation({ mutationFn: () => api.exportReport({ type, format: 'csv', ...range }), onSuccess: (data) => { notify(locale === 'ar' ? 'تم تجهيز التقرير' : 'Report export is ready'); if (data.downloadUrl) window.location.assign(data.downloadUrl); }, onError: (e) => notify(e.message, 'error') });
  const summary = query.data?.summary || {};
  return <div><PageHeader title={c.title} subtitle={c.subtitle} actions={<button className="btn-primary" disabled={exporting.isPending} onClick={() => exporting.mutate()}><Download className="h-4 w-4" />{c.generate}</button>} /><Toolbar><div className="flex gap-2">{['revenue','bookings','occupancy'].map((x) => <button key={x} onClick={() => setType(x)} className={type === x ? 'btn-primary !py-2' : 'btn-ghost !py-2'}>{c[x]}</button>)}</div><DateRangeControls value={range} onChange={setRange} compact /></Toolbar>{query.isLoading ? <LoadingBlock /> : query.isError ? <ErrorBlock error={query.error} onRetry={query.refetch} /> : <><div className="mb-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">{Object.entries(summary).map(([key, value]) => <div className="panel p-4" key={key}><p className="text-xs font-semibold capitalize text-pitch-500">{key.replaceAll('_',' ')}</p><p className="mt-2 text-2xl font-bold">{key.toLowerCase().includes('revenue') || key.toLowerCase().includes('amount') ? formatMoney(value, locale) : value}</p></div>)}</div><div className="panel overflow-x-auto"><table className="min-w-full text-sm"><thead className="table-head"><tr>{(query.data?.columns || []).map((col) => <th className="px-4 py-3 text-start" key={col.key}>{col.label}</th>)}</tr></thead><tbody>{(query.data?.items || []).map((row, i) => <tr className="table-row" key={row.id || i}>{(query.data?.columns || []).map((col) => <td className="px-4 py-3" key={col.key}>{row[col.key] ?? '—'}</td>)}</tr>)}</tbody></table>{!query.data?.items?.length ? <p className="p-10 text-center text-pitch-500">{c.empty}</p> : null}</div></>}</div>;
}

export function SettlementsPage() {
  const { locale } = useLocale();
  const { notify } = useFeedback();
  const qc = useQueryClient();
  const [range, setRange] = useState(initialRange());
  const [selected, setSelected] = useState(null);
  const c = useCopy(
    { title: 'التسويات', subtitle: 'مراجعة مستحقات الملاك ودفعها وتتبعها', create: 'إنشاء تسوية', owner: 'المالك', gross: 'الإجمالي', fee: 'العمولة', net: 'الصافي', status: 'الحالة', empty: 'لا توجد تسويات', confirm: 'تأكيد الدفع' },
    { title: 'Settlements', subtitle: 'Review, pay, and track owner payouts', create: 'Create settlement', owner: 'Owner', gross: 'Gross', fee: 'Fee', net: 'Net', status: 'Status', empty: 'No settlements', confirm: 'Confirm payment' },
  );
  const query = useQuery({ queryKey: ['admin-settlements', range], queryFn: () => api.settlements(range) });
  const pay = useMutation({ mutationFn: (id) => api.updateSettlement(id, { status: 'paid', paidAt: new Date().toISOString() }), onSuccess: () => { notify(locale === 'ar' ? 'تم تسجيل التسوية' : 'Settlement recorded'); setSelected(null); qc.invalidateQueries({ queryKey: ['admin-settlements'] }); }, onError: (e) => notify(e.message, 'error') });
  return <div><PageHeader title={c.title} subtitle={c.subtitle} actions={<button className="btn-primary"><Plus className="h-4 w-4" />{c.create}</button>} /><Toolbar><DateRangeControls value={range} onChange={setRange} /></Toolbar><QueryState query={query} empty={c.empty}>{(items) => <div className="panel overflow-x-auto"><table className="min-w-full text-sm"><thead className="table-head"><tr><th className="px-4 py-3 text-start">{c.owner}</th><th className="px-4 py-3 text-start">{c.gross}</th><th className="px-4 py-3 text-start">{c.fee}</th><th className="px-4 py-3 text-start">{c.net}</th><th className="px-4 py-3 text-start">{c.status}</th><th /></tr></thead><tbody>{items.map((x) => <tr className="table-row" key={x.id}><td className="px-4 py-3 font-semibold">{x.ownerName}</td><td className="px-4 py-3">{formatMoney(x.grossAmount, locale)}</td><td className="px-4 py-3">{formatMoney(x.platformFee, locale)}</td><td className="px-4 py-3 font-bold">{formatMoney(x.netAmount, locale)}</td><td className="px-4 py-3"><StatusBadge status={x.status} /></td><td className="px-4 py-3"><button className="btn-ghost !px-2 !py-1.5" onClick={() => setSelected(x)}><Eye className="h-4 w-4" /></button></td></tr>)}</tbody></table></div>}</QueryState>{selected ? <Modal title={`${c.owner}: ${selected.ownerName}`} onClose={() => setSelected(null)}><dl className="space-y-3">{[[c.gross, selected.grossAmount],[c.fee, selected.platformFee],[c.net, selected.netAmount]].map(([k,v]) => <div className="flex justify-between" key={k}><dt className="text-pitch-500">{k}</dt><dd className="font-bold">{formatMoney(v,locale)}</dd></div>)}</dl>{selected.status !== 'paid' ? <button className="btn-primary mt-5 w-full" disabled={pay.isPending} onClick={() => pay.mutate(selected.id)}><WalletCards className="h-4 w-4" />{c.confirm}</button> : null}</Modal> : null}</div>;
}

export function StaffPage() {
  const { locale } = useLocale();
  const { notify } = useFeedback();
  const qc = useQueryClient();
  const [invite, setInvite] = useState(false);
  const [form, setForm] = useState({ name: '', email: '', roleId: '' });
  const c = useCopy(
    { title: 'الفريق والأدوار', subtitle: 'دعوة الموظفين وتطبيق صلاحيات أقل امتيازاً', invite: 'دعوة موظف', name: 'الاسم', email: 'البريد', role: 'الدور', status: 'الحالة', empty: 'لا يوجد موظفون', permissions: 'الصلاحيات', send: 'إرسال الدعوة' },
    { title: 'Staff, roles & permissions', subtitle: 'Invite staff and enforce least-privilege access', invite: 'Invite staff', name: 'Name', email: 'Email', role: 'Role', status: 'Status', empty: 'No staff', permissions: 'Permissions', send: 'Send invitation' },
  );
  const staff = useQuery({ queryKey: ['admin-staff'], queryFn: api.staff });
  const roles = useQuery({ queryKey: ['admin-roles'], queryFn: api.roles });
  const mutation = useMutation({ mutationFn: () => api.inviteStaff(form), onSuccess: () => { notify(locale === 'ar' ? 'تم إرسال الدعوة' : 'Invitation sent'); setInvite(false); qc.invalidateQueries({ queryKey: ['admin-staff'] }); }, onError: (e) => notify(e.message, 'error') });
  return <div><PageHeader title={c.title} subtitle={c.subtitle} actions={<button className="btn-primary" onClick={() => setInvite(true)}><Plus className="h-4 w-4" />{c.invite}</button>} /><div className="grid gap-5 xl:grid-cols-[1fr_340px]"><QueryState query={staff} empty={c.empty}>{(items) => <div className="panel overflow-x-auto"><table className="min-w-full text-sm"><thead className="table-head"><tr>{[c.name,c.email,c.role,c.status].map((h) => <th className="px-4 py-3 text-start" key={h}>{h}</th>)}</tr></thead><tbody>{items.map((x) => <tr className="table-row" key={x.id}><td className="px-4 py-3 font-bold">{x.name}</td><td className="px-4 py-3">{x.email}</td><td className="px-4 py-3">{x.roleName || x.role}</td><td className="px-4 py-3"><StatusBadge status={x.status || 'active'} /></td></tr>)}</tbody></table></div>}</QueryState><aside className="panel p-4"><h2 className="mb-3 flex items-center gap-2 font-bold"><ShieldCheck className="h-5 w-5" />{c.permissions}</h2><div className="space-y-3">{(roles.data?.items || roles.data || []).map((role) => <div key={role.id} className="rounded-xl border border-pitch-100 p-3 dark:border-pitch-800"><p className="font-bold">{role.name}</p><div className="mt-2 flex flex-wrap gap-1">{(role.permissions || []).slice(0,5).map((p) => <span key={p} className="chip bg-pitch-50 dark:bg-pitch-900">{p}</span>)}</div></div>)}</div></aside></div>{invite ? <Modal title={c.invite} onClose={() => setInvite(false)}><form className="space-y-3" onSubmit={(e) => { e.preventDefault(); mutation.mutate(); }}><label><span className="label">{c.name}</span><input required className="input" value={form.name} onChange={(e) => setForm({...form,name:e.target.value})} /></label><label><span className="label">{c.email}</span><input required type="email" className="input" value={form.email} onChange={(e) => setForm({...form,email:e.target.value})} /></label><label><span className="label">{c.role}</span><select required className="input" value={form.roleId} onChange={(e) => setForm({...form,roleId:e.target.value})}><option value="">—</option>{(roles.data?.items || roles.data || []).map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}</select></label><button disabled={mutation.isPending} className="btn-primary w-full">{c.send}</button></form></Modal> : null}</div>;
}

export function AuditLogPage() {
  const { locale } = useLocale();
  const [range, setRange] = useState(initialRange(7));
  const [q, setQ] = useState('');
  const c = useCopy(
    { title: 'سجل التدقيق', subtitle: 'سجل غير قابل للتغيير لكل إجراءات الإدارة', search: 'ابحث بالمستخدم أو الإجراء أو المورد', actor: 'المنفذ', action: 'الإجراء', resource: 'المورد', ip: 'عنوان IP', time: 'الوقت', empty: 'لا توجد أحداث تدقيق' },
    { title: 'Audit log', subtitle: 'Immutable history of every administrative action', search: 'Search actor, action, or resource', actor: 'Actor', action: 'Action', resource: 'Resource', ip: 'IP address', time: 'Time', empty: 'No audit events' },
  );
  const query = useQuery({ queryKey: ['admin-audit', range, q], queryFn: () => api.auditLog({ ...range, q, limit: 100 }) });
  return <div><PageHeader title={c.title} subtitle={c.subtitle} /><Toolbar><DateRangeControls value={range} onChange={setRange} compact /><div className="relative w-full max-w-xs"><Search className="absolute start-3 top-3 h-4 w-4 text-pitch-500" /><input className="input ps-9" value={q} onChange={(e) => setQ(e.target.value)} placeholder={c.search} /></div></Toolbar><QueryState query={query} empty={c.empty}>{(items) => <div className="panel overflow-x-auto"><table className="min-w-full text-sm"><thead className="table-head"><tr>{[c.actor,c.action,c.resource,c.ip,c.time].map((h) => <th className="px-4 py-3 text-start" key={h}>{h}</th>)}</tr></thead><tbody>{items.map((x) => <tr className="table-row" key={x.id}><td className="px-4 py-3"><strong>{x.actorName}</strong><small className="block text-pitch-500">{x.actorEmail}</small></td><td className="px-4 py-3"><span className="chip bg-pitch-50 font-mono dark:bg-pitch-900">{x.action}</span></td><td className="px-4 py-3">{x.resourceType} <span className="font-mono text-xs">{x.resourceId}</span></td><td className="px-4 py-3 font-mono text-xs">{x.ipAddress || '—'}</td><td className="px-4 py-3 whitespace-nowrap">{formatDate(x.createdAt, locale)}</td></tr>)}</tbody></table></div>}</QueryState></div>;
}
