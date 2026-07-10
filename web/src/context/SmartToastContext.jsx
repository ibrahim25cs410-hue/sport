import { createContext, useContext, useState, useCallback } from 'react';
import { SmartApiError } from '../lib/smartApi';

const SmartToastContext = createContext(null);

const META = {
  success: { bg: 'bg-brand-600', icon: '✓' },
  error: { bg: 'bg-red-500', icon: '!' },
  warning: { bg: 'bg-amber-500', icon: '⚠' },
  info: { bg: 'bg-gray-800', icon: 'ℹ' },
  optimistic: { bg: 'bg-brand-500/90', icon: '…' },
};

export function SmartToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const push = useCallback((message, type = 'info', { action } = {}) => {
    const id = Date.now() + Math.random();
    setToasts((t) => [...t, { id, message, type, action }]);
    const duration = type === 'optimistic' ? 2000 : 4000;
    setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), duration);
  }, []);

  const smartError = useCallback((err) => {
    if (err instanceof SmartApiError) {
      if (err.retryable) {
        push(err.message, 'warning', {
          action: err.code === 'NETWORK' ? 'تحقق من تشغيل API على المنفذ 3000' : undefined,
        });
      } else {
        push(err.message, 'error');
      }
      return;
    }
    push(err?.message || 'حدث خطأ غير متوقع', 'error');
  }, [push]);

  const value = {
    show: push,
    success: (m) => push(m, 'success'),
    error: (m) => push(m, 'error'),
    warning: (m) => push(m, 'warning'),
    optimistic: (m) => push(m, 'optimistic'),
    smartError,
  };

  return (
    <SmartToastContext.Provider value={value}>
      {children}
      <div className="fixed top-4 left-4 right-4 z-[9999] flex flex-col gap-2 items-center pointer-events-none max-w-md mx-auto">
        {toasts.map((t) => {
          const m = META[t.type] || META.info;
          return (
            <div
              key={t.id}
              className={`${m.bg} text-white px-5 py-3 rounded-2xl shadow-lg text-sm font-medium animate-slide-up w-full`}
            >
              <p className="text-center">
                <span className="opacity-80 me-2">{m.icon}</span>
                {t.message}
              </p>
              {t.action && <p className="text-center text-xs opacity-75 mt-1">{t.action}</p>}
            </div>
          );
        })}
      </div>
    </SmartToastContext.Provider>
  );
}

export const useSmartToast = () => useContext(SmartToastContext);
