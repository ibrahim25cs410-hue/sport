import { createContext, useContext, useState, useCallback } from 'react';

const ToastContext = createContext(null);

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const show = useCallback((message, type = 'info') => {
    const id = Date.now();
    setToasts((t) => [...t, { id, message, type }]);
    setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 3500);
  }, []);

  const colors = {
    success: 'bg-brand-600',
    error: 'bg-red-500',
    info: 'bg-gray-800',
  };

  return (
    <ToastContext.Provider value={{ show }}>
      {children}
      <div className="fixed top-4 left-4 right-4 z-[9999] flex flex-col gap-2 items-center pointer-events-none max-w-md mx-auto">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={`${colors[t.type]} text-white px-5 py-3 rounded-2xl shadow-float text-sm font-medium animate-slide-up w-full text-center`}
          >
            {t.message}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export const useToast = () => useContext(ToastContext);
