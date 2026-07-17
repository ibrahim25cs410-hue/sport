import { Navigate, Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Users, Building2, CalendarDays, Wallet, LogOut, Shield,
  Settings, Sun, Moon, Languages,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useLocale } from '../context/LocaleContext';
import { useTheme } from '../context/ThemeContext';

export function RequireAdmin() {
  const { isAdmin } = useAuth();
  if (!isAdmin) return <Navigate to="/login" replace />;
  return <Outlet />;
}

function NavGroup({ title, children }) {
  return (
    <div className="mb-3">
      <p className="mb-1.5 px-3 text-[10px] font-bold uppercase tracking-wider text-pitch-500">
        {title}
      </p>
      <div className="flex gap-1 lg:flex-col">{children}</div>
    </div>
  );
}

function SideLink({ to, end, label, icon: Icon }) {
  return (
    <NavLink
      to={to}
      end={end}
      className={({ isActive }) =>
        `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold whitespace-nowrap transition ${
          isActive
            ? 'bg-white text-pitch-950'
            : 'text-pitch-200 hover:bg-pitch-900 hover:text-white'
        }`
      }
    >
      <Icon className="h-4 w-4 shrink-0" />
      {label}
    </NavLink>
  );
}

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const { t, locale, toggleLocale } = useLocale();
  const { isDark, toggleTheme } = useTheme();
  const navigate = useNavigate();
  const location = useLocation();

  const titleMap = {
    '/': t('nav.dashboard'),
    '/bookings': t('nav.bookings'),
    '/fields': t('nav.fields'),
    '/owners': t('nav.owners'),
    '/users': t('nav.users'),
    '/settings': t('nav.settings'),
  };
  const pageTitle = titleMap[location.pathname]
    || (location.pathname.startsWith('/owners/') ? t('owners.details') : t('brand'));

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="min-h-screen lg:grid lg:grid-cols-[252px_1fr]">
      <aside className="relative flex flex-col border-b border-pitch-800/30 bg-pitch-950 text-pitch-50 lg:min-h-screen lg:border-b-0 lg:border-e lg:border-pitch-900">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(480px_220px_at_50%_-10%,rgba(94,163,111,0.22),transparent_70%)]" />

        <div className="relative px-5 py-5">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-pitch-700">
              <Shield className="h-5 w-5" />
            </div>
            <div>
              <p className="text-lg font-bold tracking-tight">{t('brand')}</p>
              <p className="text-[11px] text-pitch-300">{t('brandSub')}</p>
            </div>
          </div>
        </div>

        <nav className="relative flex-1 overflow-x-auto px-3 pb-4 lg:overflow-y-auto lg:overflow-x-visible">
          <NavGroup title={t('navGroup.overview')}>
            <SideLink to="/" end label={t('nav.dashboard')} icon={LayoutDashboard} />
          </NavGroup>
          <NavGroup title={t('navGroup.operations')}>
            <SideLink to="/bookings" label={t('nav.bookings')} icon={CalendarDays} />
            <SideLink to="/fields" label={t('nav.fields')} icon={Building2} />
          </NavGroup>
          <NavGroup title={t('navGroup.people')}>
            <SideLink to="/owners" label={t('nav.owners')} icon={Wallet} />
            <SideLink to="/users" label={t('nav.users')} icon={Users} />
          </NavGroup>
          <NavGroup title={t('navGroup.system')}>
            <SideLink to="/settings" label={t('nav.settings')} icon={Settings} />
          </NavGroup>
        </nav>

        <div className="relative mt-auto space-y-3 border-t border-pitch-800/80 px-4 py-4">
          <div className="hidden grid-cols-2 gap-2 lg:grid">
            <button type="button" onClick={toggleLocale} className="btn !bg-pitch-900 !px-2 !py-2 !text-xs !text-pitch-100">
              <Languages className="h-3.5 w-3.5" />
              {locale === 'ar' ? 'EN' : 'ع'}
            </button>
            <button type="button" onClick={toggleTheme} className="btn !bg-pitch-900 !px-2 !py-2 !text-xs !text-pitch-100">
              {isDark ? <Sun className="h-3.5 w-3.5" /> : <Moon className="h-3.5 w-3.5" />}
              {isDark ? t('settings.light') : t('settings.dark')}
            </button>
          </div>
          <div className="hidden rounded-2xl bg-pitch-900/90 px-3 py-3 lg:block">
            <p className="truncate text-sm font-semibold">{user?.name}</p>
            <p className="truncate text-xs text-pitch-400">{user?.email}</p>
            <span className="mt-2 inline-flex rounded-md bg-pitch-700 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide">
              Admin
            </span>
          </div>
          <button type="button" onClick={handleLogout} className="btn hidden w-full !bg-pitch-900 !text-pitch-100 hover:!bg-pitch-800 lg:inline-flex">
            <LogOut className="h-4 w-4" />
            {t('logout')}
          </button>
        </div>
      </aside>

      <div className="min-w-0">
        <header className="sticky top-0 z-20 flex items-center justify-between gap-3 border-b border-pitch-200/70 bg-white/85 px-4 py-3 backdrop-blur-md dark:border-pitch-800 dark:bg-pitch-950/85 lg:px-8">
          <div className="min-w-0">
            <p className="truncate text-sm font-bold text-pitch-950 dark:text-pitch-50">{pageTitle}</p>
            <p className="text-xs text-pitch-500 dark:text-pitch-400">{t('liveData')}</p>
          </div>
          <div className="flex items-center gap-2">
            <button type="button" onClick={toggleLocale} className="btn-ghost !px-2.5 !py-2" title="Language">
              <Languages className="h-4 w-4" />
              <span className="hidden sm:inline">{locale === 'ar' ? 'EN' : 'ع'}</span>
            </button>
            <button type="button" onClick={toggleTheme} className="btn-ghost !px-2.5 !py-2" title="Theme">
              {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
            </button>
            <span className="hidden items-center gap-1.5 rounded-lg bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-800 dark:bg-emerald-950 dark:text-emerald-200 sm:inline-flex">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
              {t('online')}
            </span>
            <button type="button" onClick={handleLogout} className="btn-ghost lg:hidden">
              <LogOut className="h-4 w-4" />
            </button>
          </div>
        </header>
        <main className="mx-auto max-w-[1400px] px-4 py-6 lg:px-8 lg:py-7">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
