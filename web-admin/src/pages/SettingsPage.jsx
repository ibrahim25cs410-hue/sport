import { Languages, Moon, Sun, ShieldCheck } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useLocale } from '../context/LocaleContext';
import { useTheme } from '../context/ThemeContext';
import { PageHeader } from '../components/ui';

export default function SettingsPage() {
  const { user } = useAuth();
  const { t, locale, setLocale } = useLocale();
  const { theme, setTheme } = useTheme();

  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <PageHeader title={t('settings.title')} subtitle={t('settings.subtitle')} />

      <section className="panel p-5">
        <h2 className="font-bold text-pitch-950 dark:text-pitch-50">{t('settings.language')}</h2>
        <p className="mt-1 text-sm text-pitch-600 dark:text-pitch-300">{t('settings.languageHint')}</p>
        <div className="mt-4 grid gap-2 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => setLocale('ar')}
            className={`flex items-center gap-3 rounded-xl border px-4 py-3 text-start transition ${
              locale === 'ar'
                ? 'border-pitch-600 bg-pitch-50 dark:border-pitch-400 dark:bg-pitch-900'
                : 'border-pitch-200 dark:border-pitch-800'
            }`}
          >
            <Languages className="h-5 w-5 text-pitch-700 dark:text-pitch-300" />
            <span className="font-semibold">{t('settings.arabic')}</span>
          </button>
          <button
            type="button"
            onClick={() => setLocale('en')}
            className={`flex items-center gap-3 rounded-xl border px-4 py-3 text-start transition ${
              locale === 'en'
                ? 'border-pitch-600 bg-pitch-50 dark:border-pitch-400 dark:bg-pitch-900'
                : 'border-pitch-200 dark:border-pitch-800'
            }`}
          >
            <Languages className="h-5 w-5 text-pitch-700 dark:text-pitch-300" />
            <span className="font-semibold">{t('settings.english')}</span>
          </button>
        </div>
      </section>

      <section className="panel p-5">
        <h2 className="font-bold text-pitch-950 dark:text-pitch-50">{t('settings.appearance')}</h2>
        <p className="mt-1 text-sm text-pitch-600 dark:text-pitch-300">{t('settings.appearanceHint')}</p>
        <div className="mt-4 grid gap-2 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => setTheme('light')}
            className={`flex items-center gap-3 rounded-xl border px-4 py-3 text-start transition ${
              theme === 'light'
                ? 'border-pitch-600 bg-pitch-50 dark:border-pitch-400 dark:bg-pitch-900'
                : 'border-pitch-200 dark:border-pitch-800'
            }`}
          >
            <Sun className="h-5 w-5 text-amber-600" />
            <span className="font-semibold">{t('settings.light')}</span>
          </button>
          <button
            type="button"
            onClick={() => setTheme('dark')}
            className={`flex items-center gap-3 rounded-xl border px-4 py-3 text-start transition ${
              theme === 'dark'
                ? 'border-pitch-600 bg-pitch-50 dark:border-pitch-400 dark:bg-pitch-900'
                : 'border-pitch-200 dark:border-pitch-800'
            }`}
          >
            <Moon className="h-5 w-5 text-sky-500" />
            <span className="font-semibold">{t('settings.dark')}</span>
          </button>
        </div>
      </section>

      <section className="panel p-5">
        <div className="flex items-start gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-pitch-700 text-white">
            <ShieldCheck className="h-5 w-5" />
          </div>
          <div>
            <h2 className="font-bold text-pitch-950 dark:text-pitch-50">{t('settings.permissions')}</h2>
            <p className="mt-1 text-sm text-pitch-600 dark:text-pitch-300">{t('settings.permissionsHint')}</p>
          </div>
        </div>
        <ul className="mt-4 flex flex-wrap gap-2 text-sm text-pitch-700 dark:text-pitch-200">
          {Array.isArray(user?.permissions) ? user.permissions.map((permission) => (
            <li key={permission} className="rounded-lg bg-pitch-50 px-2.5 py-1.5 font-mono text-xs dark:bg-pitch-900/70">{permission}</li>
          )) : (
            <li className="rounded-xl bg-pitch-50 px-3 py-2 dark:bg-pitch-900/70">
              {locale === 'ar' ? 'جلسة مدير قديمة متوافقة — صلاحيات كاملة' : 'Legacy compatible admin session — full access'}
            </li>
          )}
        </ul>
      </section>

      <section className="panel p-5">
        <h2 className="font-bold text-pitch-950 dark:text-pitch-50">{t('settings.account')}</h2>
        <div className="mt-3 grid gap-2 text-sm sm:grid-cols-2">
          <div className="rounded-xl bg-pitch-50 px-3 py-3 dark:bg-pitch-900/70">
            <p className="text-xs text-pitch-500">{t('users.name')}</p>
            <p className="font-semibold">{user?.name}</p>
          </div>
          <div className="rounded-xl bg-pitch-50 px-3 py-3 dark:bg-pitch-900/70">
            <p className="text-xs text-pitch-500">{t('users.email')}</p>
            <p className="font-semibold">{user?.email}</p>
          </div>
        </div>
      </section>
    </div>
  );
}
