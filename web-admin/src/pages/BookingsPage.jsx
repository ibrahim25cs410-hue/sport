import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link, useSearchParams } from 'react-router-dom';
import { ChevronLeft, ChevronRight, Filter, Plus } from 'lucide-react';
import { api, formatDate, formatMoney } from '../lib/api';
import { ConfirmDialog, EmptyBlock, ErrorBlock, FilterChips, LoadingBlock, PageHeader, StatusBadge, Toolbar } from '../components/ui';
import { useLocale } from '../context/LocaleContext';
import { useFeedback } from '../context/FeedbackContext';
import { useAuth } from '../context/AuthContext';
import { PermissionGate } from '../components/PermissionGate';

export default function BookingsPage() {
  const { t, locale } = useLocale();
  const { hasPermission } = useAuth();
  const [params, setParams] = useSearchParams();
  const status = params.get('status') || 'all';
  const page = Number(params.get('page')) || 1;
  const [filters, setFilters] = useState({ q: '', from: '', to: '', fieldId: '', ownerId: '', paymentStatus: '', minAmount: '', maxAmount: '', sort: 'newest' });
  const [selected, setSelected] = useState([]);
  const [pendingAction, setPendingAction] = useState(null);
  const { notify } = useFeedback();
  const qc = useQueryClient();
  const canManage = hasPermission('bookings.manage');
  const sortParams = filters.sort === 'oldest'
    ? { sort: 'startTime', order: 'asc' }
    : filters.sort === 'amount_desc'
      ? { sort: 'totalPrice', order: 'desc' }
      : filters.sort === 'amount_asc'
        ? { sort: 'totalPrice', order: 'asc' }
        : { sort: 'startTime', order: 'desc' };
  const queryParams = {
    status, page, limit: 25, q: filters.q, from: filters.from, to: filters.to,
    fieldId: filters.fieldId, ownerId: filters.ownerId, paymentStatus: filters.paymentStatus,
    minAmount: filters.minAmount, maxAmount: filters.maxAmount, ...sortParams,
  };
  const query = useQuery({ queryKey: ['admin-bookings', queryParams], queryFn: () => api.bookings(queryParams) });
  const fields = useQuery({ queryKey: ['admin-fields'], queryFn: api.fields });
  const owners = useQuery({ queryKey: ['admin-owners'], queryFn: api.owners });
  const invalidate = () => { setSelected([]); qc.invalidateQueries({ queryKey: ['admin-bookings'] }); qc.invalidateQueries({ queryKey: ['admin-pending'] }); qc.invalidateQueries({ queryKey: ['admin-stats'] }); };
  const action = useMutation({
    mutationFn: ({ type, ids }) => ids.length > 1 ? api.bulkBookings(ids, type) : (
      type === 'approve' ? api.approveBooking(ids[0]) : type === 'reject' ? api.rejectBooking(ids[0]) : type === 'mark_paid' ? api.confirmCashPayment(ids[0]) : api.cancelBooking(ids[0])
    ),
    onSuccess: () => { notify(locale === 'ar' ? 'تم تنفيذ الإجراء' : 'Action completed'); setPendingAction(null); invalidate(); },
    onError: (e) => notify(e.message, 'error'),
  });
  const items = query.data?.items || [];
  const setPage = (value) => { const next = new URLSearchParams(params); next.set('page', value); setParams(next); };
  const toggleAll = () => setSelected(selected.length === items.length ? [] : items.map((x) => x.id));
  const labels = locale === 'ar' ? {
    dateFrom:'من تاريخ', dateTo:'إلى تاريخ', field:'الملعب', owner:'المالك', payment:'الدفع', min:'أقل مبلغ', max:'أعلى مبلغ', sort:'الترتيب',
    all:'الكل', newest:'الأحدث', oldest:'الأقدم', amountDesc:'المبلغ: الأعلى', amountAsc:'المبلغ: الأقل', selected:'محدد', bulkApprove:'موافقة', bulkReject:'رفض', bulkCancel:'إلغاء', bulkPaid:'تعليم مدفوع', page:'صفحة',
  } : {
    dateFrom:'From date', dateTo:'To date', field:'Field', owner:'Owner', payment:'Payment', min:'Min amount', max:'Max amount', sort:'Sort',
    all:'All', newest:'Newest', oldest:'Oldest', amountDesc:'Amount: high', amountAsc:'Amount: low', selected:'selected', bulkApprove:'Approve', bulkReject:'Reject', bulkCancel:'Cancel', bulkPaid:'Mark paid', page:'Page',
  };
  const filtersList = [{ id:'all',label:t('bookings.filterAll')},{id:'pending',label:t('bookings.filterPending')},{id:'approved',label:t('bookings.filterApproved')},{id:'rejected',label:t('bookings.filterRejected')},{id:'cancelled',label:t('bookings.filterCancelled')}];
  return <div>
    <PageHeader title={t('bookings.title')} subtitle={t('bookings.subtitle')} actions={<PermissionGate permission="bookings.manual"><Link className="btn-primary" to="/bookings/new"><Plus className="h-4 w-4" />{locale === 'ar' ? 'حجز يدوي' : 'Manual booking'}</Link></PermissionGate>} />
    <Toolbar><FilterChips options={filtersList} value={status} onChange={(id) => { const next=new URLSearchParams(params); id==='all'?next.delete('status'):next.set('status',id); next.delete('page'); setParams(next); }} /><input className="input max-w-sm" placeholder={t('bookings.searchPh')} value={filters.q} onChange={(e)=>setFilters({...filters,q:e.target.value})} /></Toolbar>
    <div className="panel mb-4 grid gap-3 p-3 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-8">
      <label><span className="label">{labels.dateFrom}</span><input type="date" className="input !py-2" value={filters.from} onChange={(e)=>setFilters({...filters,from:e.target.value})}/></label>
      <label><span className="label">{labels.dateTo}</span><input type="date" className="input !py-2" value={filters.to} onChange={(e)=>setFilters({...filters,to:e.target.value})}/></label>
      <label><span className="label">{labels.field}</span><select className="input !py-2" value={filters.fieldId} onChange={(e)=>setFilters({...filters,fieldId:e.target.value})}><option value="">{labels.all}</option>{(fields.data||[]).map(x=><option key={x.id} value={x.id}>{x.name}</option>)}</select></label>
      <label><span className="label">{labels.owner}</span><select className="input !py-2" value={filters.ownerId} onChange={(e)=>setFilters({...filters,ownerId:e.target.value})}><option value="">{labels.all}</option>{(owners.data||[]).map(x=><option key={x.id} value={x.id}>{x.name}</option>)}</select></label>
      <label><span className="label">{labels.payment}</span><select className="input !py-2" value={filters.paymentStatus} onChange={(e)=>setFilters({...filters,paymentStatus:e.target.value})}><option value="">{labels.all}</option><option value="paid">{locale==='ar'?'مدفوع':'Paid'}</option><option value="unpaid">{locale==='ar'?'غير مدفوع':'Unpaid'}</option><option value="pay_at_venue">{locale==='ar'?'نقداً':'Cash'}</option></select></label>
      <label><span className="label">{labels.min}</span><input type="number" className="input !py-2" value={filters.minAmount} onChange={(e)=>setFilters({...filters,minAmount:e.target.value})}/></label>
      <label><span className="label">{labels.max}</span><input type="number" className="input !py-2" value={filters.maxAmount} onChange={(e)=>setFilters({...filters,maxAmount:e.target.value})}/></label>
      <label><span className="label">{labels.sort}</span><select className="input !py-2" value={filters.sort} onChange={(e)=>setFilters({...filters,sort:e.target.value})}><option value="newest">{labels.newest}</option><option value="oldest">{labels.oldest}</option><option value="amount_desc">{labels.amountDesc}</option><option value="amount_asc">{labels.amountAsc}</option></select></label>
    </div>
    {selected.length && canManage ? <div className="sticky top-16 z-10 mb-3 flex flex-wrap items-center gap-2 rounded-xl bg-pitch-950 p-3 text-white shadow-xl"><strong>{selected.length} {labels.selected}</strong>{[['approve',labels.bulkApprove],['reject',labels.bulkReject],['cancel',labels.bulkCancel],['mark_paid',labels.bulkPaid]].map(([type,label])=><button key={type} className="btn !bg-pitch-800 !px-3 !py-1.5 !text-xs" onClick={()=>setPendingAction({type,ids:selected})}>{label}</button>)}</div> : null}
    {query.isLoading ? <LoadingBlock /> : query.isError ? <ErrorBlock error={query.error} onRetry={query.refetch}/> : !items.length ? <EmptyBlock title={t('bookings.empty')} hint={t('bookings.emptyHint')}/> : <div className="panel overflow-x-auto">
      <table className="min-w-full text-sm max-md:hidden"><thead className="table-head"><tr><th className="px-3 py-3"><input type="checkbox" checked={selected.length===items.length} onChange={toggleAll}/></th>{['#',t('dash.field'),t('dash.user'),t('dash.time'),t('dash.amount'),t('dash.status'),t('dash.payment'),t('actions')].map(x=><th key={x} className="px-3 py-3 text-start">{x}</th>)}</tr></thead><tbody>{items.map(b=><tr key={b.id} className="table-row"><td className="px-3 py-3"><input type="checkbox" checked={selected.includes(b.id)} onChange={()=>setSelected(s=>s.includes(b.id)?s.filter(id=>id!==b.id):[...s,b.id])}/></td><td className="px-3 py-3 font-mono text-xs"><Link className="font-bold hover:underline" to={`/bookings/${b.id}`}>{b.referenceCode||b.id}</Link></td><td className="px-3 py-3 font-medium">{b.fieldName}</td><td className="px-3 py-3">{b.userName}<small className="block text-pitch-500">{b.userPhone}</small></td><td className="px-3 py-3 whitespace-nowrap">{formatDate(b.startTime,locale)}</td><td className="px-3 py-3 whitespace-nowrap">{formatMoney(b.totalPrice,locale)}</td><td className="px-3 py-3"><StatusBadge status={b.status}/></td><td className="px-3 py-3"><StatusBadge status={b.paymentStatus}/></td><td className="px-3 py-3">{canManage ? <button className="btn-ghost !px-2 !py-1 text-xs" onClick={()=>setPendingAction({type:b.status==='pending'?'approve':'cancel',ids:[b.id]})}>{b.status==='pending'?t('bookings.approve'):t('bookings.cancel')}</button> : '—'}</td></tr>)}</tbody></table>
      <div className="divide-y divide-pitch-100 dark:divide-pitch-800 md:hidden">{items.map(b=><div key={b.id} className="p-4"><div className="flex items-center gap-3"><input type="checkbox" checked={selected.includes(b.id)} onChange={()=>setSelected(s=>s.includes(b.id)?s.filter(id=>id!==b.id):[...s,b.id])}/><Link to={`/bookings/${b.id}`} className="flex-1 font-bold">{b.fieldName}</Link><StatusBadge status={b.status}/></div><p className="mt-2 text-sm">{b.userName} · {formatDate(b.startTime,locale)}</p><p className="mt-1 text-xs font-bold">{formatMoney(b.totalPrice,locale)}</p></div>)}</div>
      <div className="flex items-center justify-between border-t border-pitch-100 p-3 dark:border-pitch-800"><span className="text-xs text-pitch-500">{labels.page} {query.data?.page||page} · {query.data?.totalCount||items.length}</span><div className="flex gap-2"><button className="btn-ghost !px-2" disabled={page<=1} onClick={()=>setPage(page-1)}><ChevronRight className="h-4 w-4"/></button><button className="btn-ghost !px-2" disabled={!query.data?.hasNextPage} onClick={()=>setPage(page+1)}><ChevronLeft className="h-4 w-4"/></button></div></div>
    </div>}
    <ConfirmDialog open={Boolean(pendingAction)} title={locale==='ar'?'تأكيد الإجراء':'Confirm action'} message={locale==='ar'?'سيتم تسجيل الإجراء في سجل التدقيق.':'This action will be recorded in the audit log.'} cancelLabel={locale==='ar'?'تراجع':'Go back'} confirmLabel={locale==='ar'?'تأكيد':'Confirm'} busy={action.isPending} onClose={()=>setPendingAction(null)} onConfirm={()=>action.mutate(pendingAction)}/>
  </div>;
}
