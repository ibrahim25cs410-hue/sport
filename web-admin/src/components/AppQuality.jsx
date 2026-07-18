import { Component, useEffect, useState } from 'react';
import { captureException } from '../lib/monitoring';

export class ErrorBoundary extends Component {
  state = { error: null };

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    captureException(error, { componentStack: info.componentStack });
  }

  render() {
    if (!this.state.error) return this.props.children;
    const arabic = document.documentElement.lang !== 'en';
    return (
      <main className="flex min-h-screen items-center justify-center p-5" role="alert">
        <section className="panel max-w-lg p-8 text-center">
          <h1 className="text-xl font-bold">{arabic ? 'تعذر عرض الصفحة' : 'This page could not be displayed'}</h1>
          <p className="mt-2 text-sm text-pitch-600 dark:text-pitch-300">
            {arabic ? 'تم تسجيل الخطأ دون إرسال بياناتك الشخصية.' : 'The error was recorded without sending personal data.'}
          </p>
          <button className="btn-primary mt-5" onClick={() => window.location.reload()}>
            {arabic ? 'إعادة المحاولة' : 'Try again'}
          </button>
        </section>
      </main>
    );
  }
}

export function ConnectionStatus() {
  const [online, setOnline] = useState(() => navigator.onLine);
  useEffect(() => {
    const update = () => setOnline(navigator.onLine);
    window.addEventListener('online', update);
    window.addEventListener('offline', update);
    return () => {
      window.removeEventListener('online', update);
      window.removeEventListener('offline', update);
    };
  }, []);
  if (online) return null;
  const arabic = document.documentElement.lang !== 'en';
  return <div className="offline-banner" role="status" aria-live="polite">{arabic ? 'أنت غير متصل. ستُحدّث البيانات عند عودة الاتصال.' : 'You are offline. Data will refresh when connection returns.'}</div>;
}
