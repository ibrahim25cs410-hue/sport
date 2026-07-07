import { RefreshCw } from 'lucide-react';
import Button from './Button';

export default function EmptyState({
  icon: Icon,
  title,
  subtitle,
  actionLabel = 'إعادة المحاولة',
  onAction,
}) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-6 text-center">
      {Icon && (
        <div className="w-20 h-20 rounded-full bg-brand-50 flex items-center justify-center mb-5 border border-brand-100">
          <Icon className="w-10 h-10 text-brand-600" strokeWidth={1.5} />
        </div>
      )}
      <h3 className="font-bold text-lg text-brand-800 mb-2">{title}</h3>
      {subtitle && <p className="text-gray-500 text-sm max-w-xs leading-relaxed">{subtitle}</p>}
      {onAction && (
        <Button className="mt-5 !py-2.5 text-sm" onClick={onAction}>
          <RefreshCw className="w-4 h-4" />
          {actionLabel}
        </Button>
      )}
    </div>
  );
}
