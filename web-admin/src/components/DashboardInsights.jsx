import { useEffect, useMemo, useRef, useState } from 'react';
import { useMutation, useQuery } from '@tanstack/react-query';
import { BarChart3, Clock3, Eye, EyeOff, GripVertical, MapPin, Target, TrendingUp } from 'lucide-react';
import { api, formatMoney } from '../lib/api';
import { useLocale } from '../context/LocaleContext';
import { DateRangeControls } from './AdminTools';

const DEFAULT_WIDGETS = [
  { id: 'expected', visible: true },
  { id: 'realized', visible: true },
  { id: 'occupancy', visible: true },
  { id: 'peak', visible: true },
  { id: 'top', visible: true },
  { id: 'trend', visible: true },
];

function range() {
  const to = new Date(); const from = new Date(); from.setDate(from.getDate() - 29);
  return { from: from.toISOString().slice(0,10), to: to.toISOString().slice(0,10) };
}

export default function DashboardInsights({ userId, bookings = [] }) {
  const { locale } = useLocale();
  const [dates, setDates] = useState(range);
  const key = `riyada_dashboard_widgets_${userId || 'admin'}`;
  const [widgets, setWidgets] = useState(() => {
    try { return JSON.parse(localStorage.getItem(key)) || DEFAULT_WIDGETS; } catch { return DEFAULT_WIDGETS; }
  });
  const [customizing, setCustomizing] = useState(false);
  const [dragged, setDragged] = useState(null);
  const hydrated = useRef(false);
  useEffect(() => { localStorage.setItem(key, JSON.stringify(widgets)); }, [key, widgets]);
  const preferences = useQuery({ queryKey: ['admin-preferences'], queryFn: api.preferences, retry: false });
  const savePreferences = useMutation({ mutationFn: (next) => api.updatePreferences({ dashboard: { widgets: next } }) });
  useEffect(() => {
    if (hydrated.current || !preferences.isFetched) return;
    hydrated.current = true;
    const remote = preferences.data?.dashboard?.widgets;
    if (Array.isArray(remote) && remote.length) {
      const ids = new Set(remote.map((item) => item.id));
      setWidgets([...remote, ...DEFAULT_WIDGETS.filter((item) => !ids.has(item.id))]);
    }
  }, [preferences.isFetched, preferences.data]);
  const analytics = useQuery({ queryKey: ['admin-dashboard-analytics', dates], queryFn: () => api.dashboardAnalytics(dates), retry: false });
  const fallback = useMemo(() => {
    const valid = bookings.filter((b) => b.status !== 'cancelled' && b.status !== 'rejected');
    const expected = valid.reduce((sum,b) => sum + Number(b.totalPrice || 0), 0);
    const realized = valid.filter((b) => b.paymentStatus === 'paid').reduce((sum,b) => sum + Number(b.totalPrice || 0), 0);
    const hours = valid.reduce((sum,b) => sum + Number(b.hours || 1), 0);
    const hourCounts = {};
    valid.forEach((b) => { const h = new Date(b.startTime).getHours(); hourCounts[h] = (hourCounts[h] || 0) + 1; });
    const peakHour = Object.entries(hourCounts).sort((a,b) => b[1] - a[1])[0]?.[0];
    const fields = {};
    valid.forEach((b) => { fields[b.fieldName || '—'] = (fields[b.fieldName || '—'] || 0) + 1; });
    return { expectedRevenue: expected, realizedRevenue: realized, occupancyRate: Math.min(100, Math.round(hours / Math.max(1, 30 * 12) * 100)), peakHour: peakHour != null ? `${String(peakHour).padStart(2,'0')}:00` : '—', topField: Object.entries(fields).sort((a,b)=>b[1]-a[1])[0]?.[0] || '—', trend: [] };
  }, [bookings]);
  const data = { ...fallback, ...(analytics.data || {}) };
  const labels = locale === 'ar'
    ? { title:'الأداء المتوقع والمحقق', customize:'تخصيص الودجات', done:'تم', expected:'الإيراد المتوقع', realized:'الإيراد المحقق', occupancy:'نسبة الإشغال', peak:'ساعة الذروة', top:'أفضل ملعب', trend:'اتجاه الأداء', hint:'اسحب لإعادة الترتيب واضغط العين للإخفاء', comparison:'مقارنة بالفترة السابقة' }
    : { title:'Expected vs realized performance', customize:'Customize widgets', done:'Done', expected:'Expected revenue', realized:'Realized revenue', occupancy:'Occupancy', peak:'Peak hour', top:'Top field', trend:'Performance trend', hint:'Drag to reorder; use the eye to toggle visibility', comparison:'vs previous period' };
  const cards = {
    expected: { label:labels.expected, value:formatMoney(data.expectedRevenue,locale), icon:Target, tone:'text-sky-600' },
    realized: { label:labels.realized, value:formatMoney(data.realizedRevenue,locale), icon:TrendingUp, tone:'text-emerald-600' },
    occupancy: { label:labels.occupancy, value:`${data.occupancyRate || 0}%`, icon:BarChart3, tone:'text-violet-600' },
    peak: { label:labels.peak, value:data.peakHour || '—', icon:Clock3, tone:'text-amber-600' },
    top: { label:labels.top, value:data.topField || data.topMetric?.label || '—', icon:MapPin, tone:'text-pitch-600' },
  };
  const persist = (next) => {
    setWidgets(next);
    localStorage.setItem(key, JSON.stringify(next));
    savePreferences.mutate(next);
  };
  const move = (target) => {
    if (!dragged || dragged === target) return;
    const next=[...widgets]; const from=next.findIndex(x=>x.id===dragged); const to=next.findIndex(x=>x.id===target); const [item]=next.splice(from,1); next.splice(to,0,item); persist(next);
  };
  return <section className="space-y-3"><div className="flex flex-col gap-3 xl:flex-row xl:items-end xl:justify-between"><div><h2 className="font-bold">{labels.title}</h2><p className="text-xs text-pitch-500">{customizing ? labels.hint : (analytics.isError ? (locale === 'ar' ? 'عرض تقديري من بيانات الحجوزات' : 'Estimated from booking data') : labels.comparison)}</p></div><div className="flex flex-wrap items-end gap-2"><DateRangeControls compact value={dates} onChange={setDates} /><button className={customizing ? 'btn-primary !py-2' : 'btn-ghost !py-2'} onClick={() => setCustomizing((x)=>!x)}>{customizing ? labels.done : labels.customize}</button></div></div><div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">{widgets.filter((w) => w.id !== 'trend' && cards[w.id] && (w.visible || customizing)).map((w) => { const x=cards[w.id]; const Icon=x.icon; const change=data.comparison?.[w.id]; return <article draggable={customizing} onDragStart={() => setDragged(w.id)} onDragOver={(e)=>e.preventDefault()} onDrop={()=>move(w.id)} className={`panel relative p-4 transition ${!w.visible ? 'opacity-45' : ''} ${customizing ? 'cursor-grab ring-1 ring-pitch-200 dark:ring-pitch-700' : ''}`} key={w.id}>{customizing ? <><GripVertical className="absolute start-2 top-2 h-4 w-4 text-pitch-400" /><button type="button" className="absolute end-2 top-2" onClick={()=>persist(widgets.map((i)=>i.id===w.id?{...i,visible:!i.visible}:i))}>{w.visible?<Eye className="h-4 w-4"/>:<EyeOff className="h-4 w-4"/>}</button></> : null}<Icon className={`h-5 w-5 ${x.tone}`} /><p className="mt-4 text-xs font-semibold text-pitch-500">{x.label}</p><p className="mt-1 text-xl font-bold">{x.value}</p>{change!=null?<p className={`mt-1 text-xs ${change>=0?'text-emerald-600':'text-red-600'}`}>{change>=0?'+':''}{change}%</p>:null}</article>; })}</div>{widgets.find((w)=>w.id==='trend')?.visible && data.trend?.length ? <div className="panel p-5"><h3 className="mb-4 font-bold">{labels.trend}</h3><div className="flex h-44 items-end gap-1">{data.trend.map((x,i)=><div key={x.date||i} className="group flex min-w-0 flex-1 flex-col justify-end"><div title={`${x.date}: ${x.realized}`} className="rounded-t bg-pitch-600 transition hover:bg-pitch-500" style={{height:`${Math.max(4,Number(x.realized)/Math.max(...data.trend.map(y=>Number(y.realized)||0),1)*100)}%`}} /></div>)}</div></div> : null}</section>;
}
