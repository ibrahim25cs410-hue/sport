import { useLocale } from '../context/LocaleContext';

export function StatCard({ label, value, hint, icon: Icon, tone = 'default' }) {
  const tones = {
    default: 'from-pitch-50 to-white border-pitch-200/80 dark:from-pitch-900/60 dark:to-pitch-950 dark:border-pitch-800',
    money: 'from-emerald-50 to-white border-emerald-200/70 dark:from-emerald-950/40 dark:to-pitch-950 dark:border-emerald-900',
    warn: 'from-amber-50 to-white border-amber-200/70 dark:from-amber-950/40 dark:to-pitch-950 dark:border-amber-900',
    info: 'from-sky-50 to-white border-sky-200/70 dark:from-sky-950/40 dark:to-pitch-950 dark:border-sky-900',
  };
  const iconTone = {
    default: 'bg-pitch-800 text-white',
    money: 'bg-emerald-700 text-white',
    warn: 'bg-amber-600 text-white',
    info: 'bg-sky-700 text-white',
  };

  return (
    <div className={`rounded-2xl border bg-gradient-to-br p-5 shadow-panel dark:shadow-panel-dark ${tones[tone] || tones.default}`}>
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-xs font-semibold tracking-wide text-pitch-600 dark:text-pitch-300">{label}</p>
          <p className="mt-2 text-2xl font-bold tracking-tight text-pitch-950 dark:text-pitch-50">{value}</p>
          {hint ? <p className="mt-1 text-xs text-pitch-500 dark:text-pitch-400">{hint}</p> : null}
        </div>
        {Icon ? (
          <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${iconTone[tone] || iconTone.default}`}>
            <Icon className="h-5 w-5" />
          </div>
        ) : null}
      </div>
    </div>
  );
}

export function PageHeader({ title, subtitle, actions }) {
  return (
    <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-pitch-950 dark:text-pitch-50 lg:text-[1.75rem]">{title}</h1>
        {subtitle ? <p className="mt-1.5 max-w-2xl text-sm text-pitch-600 dark:text-pitch-300">{subtitle}</p> : null}
      </div>
      {actions ? <div className="flex flex-wrap gap-2">{actions}</div> : null}
    </div>
  );
}

export function StatusBadge({ status }) {
  const { t } = useLocale();
  const map = {
    pending: 'bg-amber-100 text-amber-900 ring-1 ring-amber-200 dark:bg-amber-950 dark:text-amber-200 dark:ring-amber-800',
    approved: 'bg-pitch-100 text-pitch-900 ring-1 ring-pitch-200 dark:bg-pitch-900 dark:text-pitch-100 dark:ring-pitch-700',
    rejected: 'bg-red-100 text-red-800 ring-1 ring-red-200 dark:bg-red-950 dark:text-red-200 dark:ring-red-800',
    cancelled: 'bg-stone-100 text-stone-700 ring-1 ring-stone-200 dark:bg-stone-900 dark:text-stone-300 dark:ring-stone-700',
    paid: 'bg-emerald-100 text-emerald-900 ring-1 ring-emerald-200 dark:bg-emerald-950 dark:text-emerald-200 dark:ring-emerald-800',
    unpaid: 'bg-orange-100 text-orange-900 ring-1 ring-orange-200 dark:bg-orange-950 dark:text-orange-200 dark:ring-orange-800',
    pay_at_venue: 'bg-sky-100 text-sky-900 ring-1 ring-sky-200 dark:bg-sky-950 dark:text-sky-200 dark:ring-sky-800',
    active: 'bg-pitch-100 text-pitch-900 ring-1 ring-pitch-200 dark:bg-pitch-900 dark:text-pitch-100 dark:ring-pitch-700',
    blocked: 'bg-red-100 text-red-800 ring-1 ring-red-200 dark:bg-red-950 dark:text-red-200 dark:ring-red-800',
  };
  return (
    <span className={`chip ${map[status] || 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-200'}`}>
      {t(`status.${status}`) || status}
    </span>
  );
}

export function LoadingBlock({ label }) {
  const { t } = useLocale();
  return (
    <div className="panel flex min-h-56 flex-col items-center justify-center gap-3 p-8" role="status" aria-live="polite" aria-busy="true">
      <div aria-hidden="true" className="h-8 w-8 animate-spin rounded-full border-2 border-pitch-200 border-t-pitch-700 dark:border-pitch-700 dark:border-t-pitch-300" />
      <p className="text-sm text-pitch-600 dark:text-pitch-300">{label || t('loading')}</p>
    </div>
  );
}

export function ErrorBlock({ error, onRetry }) {
  const { t } = useLocale();
  return (
    <div className="panel border-red-200 bg-red-50 p-5 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/50 dark:text-red-200" role="alert">
      <p className="font-semibold">{error?.message || t('error')}</p>
      {onRetry ? (
        <button type="button" className="btn-ghost mt-3" onClick={onRetry}>{t('retry')}</button>
      ) : null}
    </div>
  );
}

export function EmptyBlock({ title, hint }) {
  return (
    <div className="panel p-8 text-center">
      <p className="font-semibold text-pitch-800 dark:text-pitch-100">{title}</p>
      {hint ? <p className="mt-1 text-sm text-pitch-500 dark:text-pitch-400">{hint}</p> : null}
    </div>
  );
}

export function Modal({ title, children, onClose }) {
  const { t } = useLocale();
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-pitch-950/50 p-4 backdrop-blur-sm" role="presentation" onMouseDown={onClose}>
      <div className="panel max-h-[calc(100dvh-2rem)] w-full max-w-md overflow-y-auto p-5" role="dialog" aria-modal="true" aria-labelledby="modal-title" onMouseDown={(event) => event.stopPropagation()}>
        <div className="mb-4 flex items-center justify-between gap-3">
          <h3 id="modal-title" className="text-lg font-bold text-pitch-950 dark:text-pitch-50">{title}</h3>
          <button type="button" className="btn-ghost !px-3 !py-1.5" onClick={onClose}>{t('close')}</button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function ConfirmDialog({ open, title, message, confirmLabel, cancelLabel, tone = 'danger', busy, onConfirm, onClose }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-[75] flex items-center justify-center bg-pitch-950/55 p-4 backdrop-blur-sm" role="presentation" onMouseDown={onClose}>
      <div className="panel w-full max-w-md p-5" role="alertdialog" aria-modal="true" aria-labelledby="confirm-title" onMouseDown={(e) => e.stopPropagation()}>
        <h2 id="confirm-title" className="text-lg font-bold">{title}</h2>
        {message ? <p className="mt-2 text-sm text-pitch-600 dark:text-pitch-300">{message}</p> : null}
        <div className="mt-5 flex justify-end gap-2">
          <button type="button" className="btn-ghost" onClick={onClose}>{cancelLabel}</button>
          <button type="button" className={tone === 'danger' ? 'btn-danger' : 'btn-primary'} disabled={busy} onClick={onConfirm}>{confirmLabel}</button>
        </div>
      </div>
    </div>
  );
}

export function Toolbar({ children }) {
  return (
    <div className="mb-4 flex flex-col gap-3 rounded-2xl border border-pitch-200/70 bg-white/70 p-3 dark:border-pitch-800 dark:bg-pitch-950/60 lg:flex-row lg:items-center lg:justify-between">
      {children}
    </div>
  );
}

export function FilterChips({ options, value, onChange }) {
  return (
    <div className="flex flex-wrap gap-2">
      {options.map((opt) => (
        <button
          key={opt.id}
          type="button"
          onClick={() => onChange(opt.id)}
          className={`rounded-lg px-3 py-1.5 text-sm font-semibold transition ${
            value === opt.id
              ? 'bg-pitch-700 text-white dark:bg-pitch-500'
              : 'border border-pitch-200 bg-white text-pitch-700 dark:border-pitch-700 dark:bg-pitch-900 dark:text-pitch-200'
          }`}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}
