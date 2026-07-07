import { AlertTriangle } from 'lucide-react';
import Button from './Button';

export default function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'تأكيد',
  cancelLabel = 'إلغاء',
  variant = 'danger',
  loading = false,
  onConfirm,
  onCancel,
}) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4">
      <button
        type="button"
        className="absolute inset-0 bg-black/45 backdrop-blur-sm"
        aria-label="إغلاق"
        onClick={onCancel}
      />
      <div
        role="dialog"
        aria-modal="true"
        className="relative w-full max-w-sm bg-white rounded-2xl shadow-float p-6 animate-slide-up"
      >
        <div className="flex flex-col items-center text-center">
          <div className={`w-14 h-14 rounded-2xl flex items-center justify-center mb-4 ${
            variant === 'danger' ? 'bg-red-50 text-red-600' : 'bg-brand-50 text-brand-600'
          }`}>
            <AlertTriangle className="w-7 h-7" />
          </div>
          <h2 className="font-bold text-lg text-gray-900 mb-2">{title}</h2>
          <p className="text-gray-500 text-sm leading-relaxed mb-6">{message}</p>
          <div className="flex gap-3 w-full">
            <Button variant="secondary" className="flex-1 !py-2.5" onClick={onCancel} disabled={loading}>
              {cancelLabel}
            </Button>
            <Button
              variant={variant === 'danger' ? 'danger' : 'primary'}
              className="flex-1 !py-2.5"
              loading={loading}
              onClick={onConfirm}
            >
              {confirmLabel}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
