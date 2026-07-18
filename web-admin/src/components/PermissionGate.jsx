import { Navigate } from 'react-router-dom';
import { LockKeyhole } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useLocale } from '../context/LocaleContext';

export function PermissionGate({ permission, children, fallback = null }) {
  const { hasPermission } = useAuth();
  return hasPermission(permission) ? children : fallback;
}

export function RequirePermission({ permission, children }) {
  const { hasPermission } = useAuth();
  return hasPermission(permission) ? children : <Navigate to="/forbidden" replace />;
}

export function ForbiddenPage() {
  const { locale } = useLocale();
  return (
    <div className="panel mx-auto max-w-lg p-10 text-center">
      <LockKeyhole className="mx-auto h-10 w-10 text-amber-600" />
      <h1 className="mt-4 text-xl font-bold">{locale === 'ar' ? 'لا تملك صلاحية الوصول' : 'Access denied'}</h1>
      <p className="mt-2 text-sm text-pitch-500">{locale === 'ar' ? 'اطلب من مدير النظام منحك الصلاحية المطلوبة.' : 'Ask a system administrator to grant the required permission.'}</p>
    </div>
  );
}
