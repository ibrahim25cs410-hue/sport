import { Component, useEffect, useState } from 'react';
import { captureException } from '../lib/monitoring';

const copy = () => document.documentElement.lang === 'en'
  ? { title: 'Something went wrong', body: 'No personal data was included in the error report.', retry: 'Try again', offline: 'You are offline. Some information may be outdated.' }
  : { title: 'حدث خطأ غير متوقع', body: 'لم يتم تضمين بياناتك الشخصية في تقرير الخطأ.', retry: 'إعادة المحاولة', offline: 'أنت غير متصل. قد تكون بعض المعلومات قديمة.' };

export class ErrorBoundary extends Component {
  state = { error: null };
  static getDerivedStateFromError(error) { return { error }; }
  componentDidCatch(error, info) { captureException(error, { componentStack: info.componentStack }); }
  render() {
    if (!this.state.error) return this.props.children;
    const text = copy();
    return <main className="app-shell flex min-h-screen items-center justify-center p-5" role="alert"><section className="card text-center"><h1 className="text-xl font-bold">{text.title}</h1><p className="mt-2 text-sm text-gray-600">{text.body}</p><button className="btn-primary mt-5" onClick={() => window.location.reload()}>{text.retry}</button></section></main>;
  }
}

export function ConnectionStatus() {
  const [online, setOnline] = useState(() => navigator.onLine);
  useEffect(() => {
    const update = () => setOnline(navigator.onLine);
    window.addEventListener('online', update);
    window.addEventListener('offline', update);
    return () => { window.removeEventListener('online', update); window.removeEventListener('offline', update); };
  }, []);
  return online ? null : <div className="offline-banner" role="status" aria-live="polite">{copy().offline}</div>;
}
