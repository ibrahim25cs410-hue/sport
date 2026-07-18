import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { Shield, Languages, Sun, Moon } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useLocale } from '../context/LocaleContext';
import { useTheme } from '../context/ThemeContext';

export default function LoginPage() {
  const { login, busy, error, isAdmin, setError } = useAuth();
  const { t, locale, toggleLocale } = useLocale();
  const { isDark, toggleTheme } = useTheme();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  if (isAdmin) return <Navigate to="/" replace />;

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    try {
      await login(email.trim(), password);
    } catch {
      /* shown via context */
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center px-4 py-10">
      <div className="absolute start-4 top-4 flex gap-2">
        <button type="button" className="btn-ghost !px-3 !py-2" onClick={toggleLocale} aria-label={locale === 'ar' ? 'Switch to English' : 'التبديل إلى العربية'}>
          <Languages className="h-4 w-4" />
          {locale === 'ar' ? 'EN' : 'ع'}
        </button>
        <button type="button" className="btn-ghost !px-3 !py-2" onClick={toggleTheme} aria-label={isDark ? (locale === 'ar' ? 'الوضع الفاتح' : 'Light theme') : (locale === 'ar' ? 'الوضع الداكن' : 'Dark theme')}>
          {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
        </button>
      </div>

      <div className="w-full max-w-md">
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-pitch-800 text-white shadow-panel dark:bg-pitch-600">
            <Shield className="h-7 w-7" />
          </div>
          <h1 className="text-3xl font-bold tracking-tight text-pitch-950 dark:text-pitch-50">{t('login.title')}</h1>
          <p className="mt-2 text-sm text-pitch-600 dark:text-pitch-300">{t('login.subtitle')}</p>
        </div>

        <form onSubmit={onSubmit} className="panel p-6">
          <label className="label" htmlFor="email">{t('login.email')}</label>
          <input
            id="email"
            className="input mb-4"
            type="email"
            autoComplete="username"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />

          <label className="label" htmlFor="password">{t('login.password')}</label>
          <input
            id="password"
            className="input mb-4"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />

          {error ? (
            <div className="mb-4 rounded-xl bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/60 dark:text-red-200" role="alert" aria-live="assertive">
              {error === 'NOT_ADMIN' ? t('login.notAdmin') : error}
            </div>
          ) : null}

          <button type="submit" className="btn-primary w-full" disabled={busy}>
            {busy ? t('login.submitting') : t('login.submit')}
          </button>
        </form>

        <p className="mt-4 text-center text-xs text-pitch-500 dark:text-pitch-400">{t('login.hint')}</p>
      </div>
    </div>
  );
}
