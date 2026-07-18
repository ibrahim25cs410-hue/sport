import { useCallback, useEffect, useState } from 'react';
import { Navigate, Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import {
  LayoutDashboard, Users, Building2, CalendarDays, Wallet, LogOut, Shield,
  Settings, Sun, Moon, Languages, Menu, X, Search, Bell, FileBarChart,
  HandCoins, ScrollText, MonitorUp, CircleHelp, Wrench,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useLocale } from '../context/LocaleContext';
import { useTheme } from '../context/ThemeContext';
import { CommandPalette, ShortcutHelp } from './AdminTools';
import { useAdminRealtime } from '../hooks/useAdminRealtime';
import { PermissionGate } from './PermissionGate';
import { api } from '../lib/api';

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
      <div className="flex flex-col gap-1">{children}</div>
    </div>
  );
}

function SideLink({ to, end, label, icon: Icon, onNavigate }) {
  return (
    <NavLink
      to={to}
      end={end}
      onClick={onNavigate}
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
  const { user, logout, hasPermission } = useAuth();
  const { t, locale, toggleLocale } = useLocale();
  const { isDark, toggleTheme } = useTheme();
  const navigate = useNavigate();
  const location = useLocation();
  const qc = useQueryClient();
  const [drawer, setDrawer] = useState(false);
  const [palette, setPalette] = useState(false);
  const [help, setHelp] = useState(false);
  const [displayMode, setDisplayMode] = useState(false);
  const realtimeEvent = useCallback((event) => {
    if (event?.type?.startsWith('booking')) qc.invalidateQueries({ queryKey: ['admin-bookings'] });
    if (event?.type?.startsWith('alert')) qc.invalidateQueries({ queryKey: ['admin-alerts'] });
    qc.invalidateQueries({ queryKey: ['admin-stats'] });
  }, [qc]);
  const canReadAlerts = hasPermission('alerts.read');
  const canSearch = hasPermission('dashboard.read');
  const realtimeStatus = useAdminRealtime(realtimeEvent, canReadAlerts);
  const alerts = useQuery({
    queryKey: ['admin-alerts-unread'],
    queryFn: () => api.alerts({ unread: true, limit: 1 }),
    enabled: canReadAlerts,
    refetchInterval: 60_000,
  });
  const unreadCount = alerts.data?.unreadCount || 0;

  const titleMap = {
    '/': t('nav.dashboard'),
    '/bookings': t('nav.bookings'),
    '/calendar': locale === 'ar' ? 'التقويم' : 'Calendar',
    '/alerts': locale === 'ar' ? 'الإشعارات' : 'Notifications',
    '/reports': locale === 'ar' ? 'التقارير' : 'Reports',
    '/settlements': locale === 'ar' ? 'التسويات' : 'Settlements',
    '/staff': locale === 'ar' ? 'الفريق والصلاحيات' : 'Staff & permissions',
    '/audit-log': locale === 'ar' ? 'سجل التدقيق' : 'Audit log',
    '/maintenance/new': locale === 'ar' ? 'الصيانة' : 'Maintenance',
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

  useEffect(() => {
    let pendingG = false;
    const handler = (e) => {
      const target = e.target;
      if (target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement || target instanceof HTMLSelectElement) return;
      if (canSearch && (e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); setPalette(true); return; }
      if (e.key === '?') { e.preventDefault(); setHelp(true); return; }
      if (pendingG && e.key.toLowerCase() === 'b') { navigate('/bookings'); pendingG = false; }
      else if (pendingG && e.key.toLowerCase() === 'c') { navigate('/calendar'); pendingG = false; }
      else pendingG = e.key.toLowerCase() === 'g';
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [navigate, canSearch]);

  const closeDrawer = () => setDrawer(false);
  const nav = (
    <>
      <NavGroup title={t('navGroup.overview')}>
        <PermissionGate permission="dashboard.read"><SideLink onNavigate={closeDrawer} to="/" end label={t('nav.dashboard')} icon={LayoutDashboard} /></PermissionGate>
      </NavGroup>
      <NavGroup title={t('navGroup.operations')}>
        <PermissionGate permission="bookings.read"><SideLink onNavigate={closeDrawer} to="/bookings" label={t('nav.bookings')} icon={CalendarDays} /></PermissionGate>
        <PermissionGate permission="bookings.read"><SideLink onNavigate={closeDrawer} to="/calendar" label={locale === 'ar' ? 'التقويم' : 'Calendar'} icon={CalendarDays} /></PermissionGate>
        <PermissionGate permission="maintenance.manage"><SideLink onNavigate={closeDrawer} to="/maintenance/new" label={locale === 'ar' ? 'الصيانة' : 'Maintenance'} icon={Wrench} /></PermissionGate>
        <PermissionGate permission="fields.read"><SideLink onNavigate={closeDrawer} to="/fields" label={t('nav.fields')} icon={Building2} /></PermissionGate>
        <PermissionGate permission="alerts.read"><SideLink onNavigate={closeDrawer} to="/alerts" label={locale === 'ar' ? 'الإشعارات' : 'Notifications'} icon={Bell} /></PermissionGate>
      </NavGroup>
      <NavGroup title={locale === 'ar' ? 'المالية والتحليل' : 'Finance & insight'}>
        <PermissionGate permission="finance.read"><SideLink onNavigate={closeDrawer} to="/reports" label={locale === 'ar' ? 'التقارير' : 'Reports'} icon={FileBarChart} /></PermissionGate>
        <PermissionGate permission="settlements.read"><SideLink onNavigate={closeDrawer} to="/settlements" label={locale === 'ar' ? 'التسويات' : 'Settlements'} icon={HandCoins} /></PermissionGate>
        <PermissionGate permission="finance.read"><SideLink onNavigate={closeDrawer} to="/owners" label={t('nav.owners')} icon={Wallet} /></PermissionGate>
      </NavGroup>
      <NavGroup title={t('navGroup.people')}>
        <PermissionGate permission="users.read"><SideLink onNavigate={closeDrawer} to="/users" label={t('nav.users')} icon={Users} /></PermissionGate>
        <PermissionGate permission="admins.manage"><SideLink onNavigate={closeDrawer} to="/staff" label={locale === 'ar' ? 'الفريق والصلاحيات' : 'Staff & roles'} icon={Shield} /></PermissionGate>
      </NavGroup>
      <NavGroup title={t('navGroup.system')}>
        <PermissionGate permission="audit.read"><SideLink onNavigate={closeDrawer} to="/audit-log" label={locale === 'ar' ? 'سجل التدقيق' : 'Audit log'} icon={ScrollText} /></PermissionGate>
        <SideLink onNavigate={closeDrawer} to="/settings" label={t('nav.settings')} icon={Settings} />
      </NavGroup>
    </>
  );

  return (
    <div className={`min-h-screen ${displayMode ? '' : 'lg:grid lg:grid-cols-[252px_1fr]'}`}>
      {drawer ? <button aria-label="Close menu" className="fixed inset-0 z-40 bg-pitch-950/50 lg:hidden" onClick={closeDrawer} /> : null}
      <aside className={`${displayMode ? 'hidden' : ''} fixed inset-y-0 start-0 z-50 flex w-[280px] -translate-x-full flex-col bg-pitch-950 text-pitch-50 transition-transform rtl:translate-x-full lg:static lg:w-auto lg:translate-x-0 rtl:lg:translate-x-0 ${drawer ? '!translate-x-0' : ''}`}>
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(480px_220px_at_50%_-10%,rgba(94,163,111,0.22),transparent_70%)]" />

        <div className="relative flex items-center justify-between px-5 py-5">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-pitch-700">
              <Shield className="h-5 w-5" />
            </div>
            <div>
              <p className="text-lg font-bold tracking-tight">{t('brand')}</p>
              <p className="text-[11px] text-pitch-300">{t('brandSub')}</p>
            </div>
          </div>
          <button className="lg:hidden" onClick={closeDrawer}><X className="h-5 w-5" /></button>
        </div>

        <nav className="relative flex-1 overflow-y-auto px-3 pb-4">{nav}</nav>

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
          <div className="flex min-w-0 items-center gap-3">
            {!displayMode ? <button className="btn-ghost !px-2 lg:hidden" onClick={() => setDrawer(true)}><Menu className="h-5 w-5" /></button> : null}
            <div className="min-w-0">
            <p className="truncate text-sm font-bold text-pitch-950 dark:text-pitch-50">{pageTitle}</p>
            <p className="text-xs text-pitch-500 dark:text-pitch-400">{t('liveData')}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {canSearch ? <button type="button" onClick={() => setPalette(true)} className="btn-ghost !px-2.5 !py-2" title={locale === 'ar' ? 'بحث' : 'Search'}><Search className="h-4 w-4" /><span className="hidden xl:inline">⌘ K</span></button> : null}
            {canReadAlerts ? <button type="button" onClick={() => navigate('/alerts')} className="btn-ghost relative !px-2.5 !py-2" title={locale === 'ar' ? 'الإشعارات' : 'Notifications'}><Bell className="h-4 w-4" />{unreadCount ? <span className="absolute -end-1 -top-1 min-w-5 rounded-full bg-amber-500 px-1 text-[10px] font-bold leading-5 text-white">{unreadCount > 99 ? '99+' : unreadCount}</span> : null}</button> : null}
            <button type="button" onClick={toggleLocale} className="btn-ghost !px-2.5 !py-2" title="Language">
              <Languages className="h-4 w-4" />
              <span className="hidden sm:inline">{locale === 'ar' ? 'EN' : 'ع'}</span>
            </button>
            <button type="button" onClick={toggleTheme} className="btn-ghost !px-2.5 !py-2" title="Theme">
              {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
            </button>
            <button type="button" onClick={() => setDisplayMode((x) => !x)} className="btn-ghost !px-2.5 !py-2" title="Operations display"><MonitorUp className="h-4 w-4" /></button>
            <button type="button" onClick={() => setHelp(true)} className="btn-ghost hidden !px-2.5 !py-2 sm:inline-flex"><CircleHelp className="h-4 w-4" /></button>
            <span className={`hidden items-center gap-1.5 rounded-lg px-2.5 py-1 text-xs font-semibold sm:inline-flex ${realtimeStatus === 'online' ? 'bg-emerald-50 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-200' : 'bg-amber-50 text-amber-800 dark:bg-amber-950 dark:text-amber-200'}`}>
              <span className={`h-1.5 w-1.5 rounded-full ${realtimeStatus === 'online' ? 'bg-emerald-500' : 'bg-amber-500'}`} />
              {realtimeStatus === 'online' ? t('online') : (locale === 'ar' ? 'إعادة اتصال' : 'Reconnecting')}
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
      {canSearch ? <CommandPalette open={palette} onClose={() => setPalette(false)} /> : null}
      <ShortcutHelp open={help} onClose={() => setHelp(false)} />
    </div>
  );
}
