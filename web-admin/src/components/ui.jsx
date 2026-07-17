export function StatCard({ label, value, hint, icon: Icon, tone = 'default' }) {
  const tones = {
    default: 'from-pitch-50 to-white border-pitch-200/80',
    money: 'from-emerald-50 to-white border-emerald-200/70',
    warn: 'from-amber-50 to-white border-amber-200/70',
    info: 'from-sky-50 to-white border-sky-200/70',
  };
  const iconTone = {
    default: 'bg-pitch-800 text-white',
    money: 'bg-emerald-700 text-white',
    warn: 'bg-amber-600 text-white',
    info: 'bg-sky-700 text-white',
  };

  return (
    <div className={`rounded-2xl border bg-gradient-to-br p-5 shadow-panel ${tones[tone] || tones.default}`}>
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-semibold tracking-wide text-pitch-600">{label}</p>
          <p className="mt-2 text-2xl font-bold tracking-tight text-pitch-950">{value}</p>
          {hint ? <p className="mt-1 text-xs text-pitch-500">{hint}</p> : null}
        </div>
        {Icon ? (
          <div className={`flex h-10 w-10 items-center justify-center rounded-xl ${iconTone[tone] || iconTone.default}`}>
            <Icon className="h-5 w-5" />
          </div>
        ) : null}
      </div>
    </div>
  );
}

export function PageHeader({ title, subtitle, actions }) {
  return (
    <div className="mb-7 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-pitch-950 lg:text-3xl">{title}</h1>
        {subtitle ? <p className="mt-1.5 text-sm text-pitch-600">{subtitle}</p> : null}
      </div>
      {actions ? <div className="flex flex-wrap gap-2">{actions}</div> : null}
    </div>
  );
}

export function StatusBadge({ status }) {
  const map = {
    pending: 'bg-amber-100 text-amber-900 ring-1 ring-amber-200',
    approved: 'bg-pitch-100 text-pitch-900 ring-1 ring-pitch-200',
    rejected: 'bg-red-100 text-red-800 ring-1 ring-red-200',
    cancelled: 'bg-stone-100 text-stone-700 ring-1 ring-stone-200',
    paid: 'bg-emerald-100 text-emerald-900 ring-1 ring-emerald-200',
    unpaid: 'bg-orange-100 text-orange-900 ring-1 ring-orange-200',
    pay_at_venue: 'bg-sky-100 text-sky-900 ring-1 ring-sky-200',
    active: 'bg-pitch-100 text-pitch-900 ring-1 ring-pitch-200',
    blocked: 'bg-red-100 text-red-800 ring-1 ring-red-200',
  };
  const labels = {
    pending: 'معلّق',
    approved: 'موافق',
    rejected: 'مرفوض',
    cancelled: 'ملغى',
    paid: 'مدفوع',
    unpaid: 'غير مدفوع',
    pay_at_venue: 'نقداً في الملعب',
    active: 'نشط',
    blocked: 'موقوف',
  };
  return (
    <span className={`inline-flex rounded-lg px-2.5 py-1 text-xs font-bold ${map[status] || 'bg-gray-100 text-gray-700'}`}>
      {labels[status] || status}
    </span>
  );
}

export function LoadingBlock({ label = 'جاري تحميل لوحة التحكم...' }) {
  return (
    <div className="panel flex min-h-56 flex-col items-center justify-center gap-3 p-8">
      <div className="h-8 w-8 animate-spin rounded-full border-2 border-pitch-200 border-t-pitch-700" />
      <p className="text-sm text-pitch-600">{label}</p>
    </div>
  );
}

export function ErrorBlock({ error, onRetry }) {
  return (
    <div className="panel border-red-200 bg-red-50 p-5 text-sm text-red-700">
      <p className="font-semibold">{error?.message || 'حدث خطأ'}</p>
      {onRetry ? (
        <button type="button" className="btn-ghost mt-3" onClick={onRetry}>إعادة المحاولة</button>
      ) : null}
    </div>
  );
}

export function EmptyBlock({ title, hint }) {
  return (
    <div className="panel p-8 text-center">
      <p className="font-semibold text-pitch-800">{title}</p>
      {hint ? <p className="mt-1 text-sm text-pitch-500">{hint}</p> : null}
    </div>
  );
}

export function Modal({ title, children, onClose }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-pitch-950/45 p-4">
      <div className="panel w-full max-w-md p-5">
        <div className="mb-4 flex items-center justify-between gap-3">
          <h3 className="text-lg font-bold">{title}</h3>
          <button type="button" className="btn-ghost !px-3 !py-1.5" onClick={onClose}>إغلاق</button>
        </div>
        {children}
      </div>
    </div>
  );
}
