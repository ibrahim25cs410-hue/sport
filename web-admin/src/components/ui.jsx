export function StatCard({ label, value, hint }) {
  return (
    <div className="panel p-5">
      <p className="text-xs font-semibold text-pitch-600">{label}</p>
      <p className="mt-2 text-2xl font-bold tracking-tight text-pitch-950">{value}</p>
      {hint ? <p className="mt-1 text-xs text-pitch-500">{hint}</p> : null}
    </div>
  );
}

export function PageHeader({ title, subtitle, actions }) {
  return (
    <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-pitch-950">{title}</h1>
        {subtitle ? <p className="mt-1 text-sm text-pitch-600">{subtitle}</p> : null}
      </div>
      {actions ? <div className="flex flex-wrap gap-2">{actions}</div> : null}
    </div>
  );
}

export function StatusBadge({ status }) {
  const map = {
    pending: 'bg-amber-100 text-amber-800',
    approved: 'bg-pitch-100 text-pitch-800',
    rejected: 'bg-red-100 text-red-700',
    cancelled: 'bg-gray-100 text-gray-600',
    paid: 'bg-emerald-100 text-emerald-800',
    unpaid: 'bg-orange-100 text-orange-800',
    pay_at_venue: 'bg-sky-100 text-sky-800',
    active: 'bg-pitch-100 text-pitch-800',
    blocked: 'bg-red-100 text-red-700',
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
    <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-bold ${map[status] || 'bg-gray-100 text-gray-700'}`}>
      {labels[status] || status}
    </span>
  );
}

export function LoadingBlock({ label = 'جاري التحميل...' }) {
  return (
    <div className="panel flex min-h-40 items-center justify-center p-8 text-sm text-pitch-600">
      {label}
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
