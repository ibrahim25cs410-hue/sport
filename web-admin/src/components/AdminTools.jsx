import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { CalendarPlus, Command, FileText, Search, ShieldCheck, Wrench, X } from 'lucide-react';
import { api } from '../lib/api';
import { useLocale } from '../context/LocaleContext';
import { useAuth } from '../context/AuthContext';

export function DateRangeControls({ value, onChange, compact = false }) {
  const { locale } = useLocale();
  const labels = locale === 'ar'
    ? { from: 'من', to: 'إلى', today: 'اليوم', week: '7 أيام', month: '30 يوماً' }
    : { from: 'From', to: 'To', today: 'Today', week: '7 days', month: '30 days' };
  const preset = (days) => {
    const to = new Date();
    const from = new Date();
    from.setDate(from.getDate() - days + 1);
    onChange({ from: from.toISOString().slice(0, 10), to: to.toISOString().slice(0, 10) });
  };
  return (
    <div className={`flex flex-wrap items-end gap-2 ${compact ? 'text-xs' : ''}`}>
      <label><span className="label">{labels.from}</span><input type="date" className="input !py-2" value={value.from || ''} onChange={(e) => onChange({ ...value, from: e.target.value })} /></label>
      <label><span className="label">{labels.to}</span><input type="date" className="input !py-2" value={value.to || ''} onChange={(e) => onChange({ ...value, to: e.target.value })} /></label>
      <div className="flex gap-1.5">
        <button type="button" className="btn-ghost !px-2.5 !py-2" onClick={() => preset(1)}>{labels.today}</button>
        <button type="button" className="btn-ghost !px-2.5 !py-2" onClick={() => preset(7)}>{labels.week}</button>
        <button type="button" className="btn-ghost !px-2.5 !py-2" onClick={() => preset(30)}>{labels.month}</button>
      </div>
    </div>
  );
}

export function CommandPalette({ open, onClose }) {
  const [query, setQuery] = useState('');
  const navigate = useNavigate();
  const { locale } = useLocale();
  const { hasPermission } = useAuth();
  const remote = useQuery({
    queryKey: ['admin-search', query],
    queryFn: () => api.globalSearch(query),
    enabled: open && query.trim().length >= 2,
    staleTime: 30_000,
  });
  const commands = useMemo(() => [
    { label: locale === 'ar' ? 'إنشاء حجز يدوي' : 'Create manual booking', path: '/bookings/new', icon: CalendarPlus, permission: 'bookings.manual' },
    { label: locale === 'ar' ? 'إضافة وقت صيانة' : 'Add maintenance block', path: '/maintenance/new', icon: Wrench, permission: 'maintenance.manage' },
    { label: locale === 'ar' ? 'فتح التقارير' : 'Open reports', path: '/reports', icon: FileText, permission: 'finance.read' },
    { label: locale === 'ar' ? 'إدارة الصلاحيات' : 'Manage permissions', path: '/staff', icon: ShieldCheck, permission: 'admins.manage' },
  ].filter((item) => hasPermission(item.permission)), [locale, hasPermission]);
  const results = remote.data?.items || [];
  const choose = (path) => { navigate(path); onClose(); setQuery(''); };

  useEffect(() => {
    if (!open) return undefined;
    const handler = (e) => { if (e.key === 'Escape') onClose(); };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [open, onClose]);
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[70] flex items-start justify-center bg-pitch-950/60 p-4 pt-[12vh] backdrop-blur-sm" onMouseDown={onClose}>
      <div className="panel w-full max-w-2xl overflow-hidden" onMouseDown={(e) => e.stopPropagation()}>
        <div className="flex items-center gap-3 border-b border-pitch-200 px-4 dark:border-pitch-800">
          <Search className="h-5 w-5 text-pitch-500" />
          <input autoFocus className="h-14 flex-1 bg-transparent outline-none" value={query} onChange={(e) => setQuery(e.target.value)} placeholder={locale === 'ar' ? 'ابحث أو اكتب أمراً...' : 'Search or type a command...'} />
          <button type="button" onClick={onClose}><X className="h-5 w-5" /></button>
        </div>
        <div className="max-h-[55vh] overflow-y-auto p-2">
          <p className="px-3 py-2 text-[10px] font-bold uppercase tracking-wider text-pitch-500">{query ? (locale === 'ar' ? 'النتائج' : 'Results') : (locale === 'ar' ? 'إجراءات سريعة' : 'Quick actions')}</p>
          {(query ? results : commands).map((item) => {
            const Icon = item.icon || Search;
            const path = item.path || `/${item.type || 'bookings'}/${item.id}`;
            return <button key={`${path}-${item.id || item.label}`} type="button" onClick={() => choose(path)} className="flex w-full items-center gap-3 rounded-xl px-3 py-3 text-start text-sm hover:bg-pitch-50 dark:hover:bg-pitch-900"><Icon className="h-4 w-4" /><span className="flex-1 font-semibold">{item.label || item.name || item.title}</span><span className="text-xs text-pitch-500">{item.type}</span></button>;
          })}
          {query.length >= 2 && !remote.isLoading && !results.length ? <p className="p-6 text-center text-sm text-pitch-500">{locale === 'ar' ? 'لا توجد نتائج' : 'No results'}</p> : null}
        </div>
      </div>
    </div>
  );
}

export function ShortcutHelp({ open, onClose }) {
  const { locale } = useLocale();
  if (!open) return null;
  const rows = locale === 'ar'
    ? [['Ctrl / ⌘ + K', 'البحث والأوامر'], ['G ثم B', 'الحجوزات'], ['G ثم C', 'التقويم'], ['?', 'هذه المساعدة']]
    : [['Ctrl / ⌘ + K', 'Search and commands'], ['G then B', 'Bookings'], ['G then C', 'Calendar'], ['?', 'This help']];
  return (
    <div className="fixed inset-0 z-[70] flex items-center justify-center bg-pitch-950/55 p-4" onMouseDown={onClose}>
      <div className="panel w-full max-w-md p-5" onMouseDown={(e) => e.stopPropagation()}>
        <div className="mb-4 flex items-center justify-between"><h2 className="flex items-center gap-2 text-lg font-bold"><Command className="h-5 w-5" />{locale === 'ar' ? 'الاختصارات' : 'Keyboard shortcuts'}</h2><button onClick={onClose}><X className="h-5 w-5" /></button></div>
        <div className="space-y-2">{rows.map(([key, text]) => <div key={key} className="flex items-center justify-between rounded-xl bg-pitch-50 p-3 dark:bg-pitch-900"><span>{text}</span><kbd className="rounded-md border border-pitch-200 bg-white px-2 py-1 font-mono text-xs dark:border-pitch-700 dark:bg-pitch-950">{key}</kbd></div>)}</div>
      </div>
    </div>
  );
}
