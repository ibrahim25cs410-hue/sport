import { Navigate, Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Users, Building2, CalendarDays, Wallet, LogOut, Shield,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const links = [
  { to: '/', end: true, label: 'لوحة التحكم', icon: LayoutDashboard },
  { to: '/bookings', label: 'الحجوزات', icon: CalendarDays },
  { to: '/fields', label: 'الملاعب', icon: Building2 },
  { to: '/owners', label: 'الملاك', icon: Wallet },
  { to: '/users', label: 'المستخدمون', icon: Users },
];

const titles = {
  '/': 'لوحة التحكم',
  '/bookings': 'الحجوزات',
  '/fields': 'الملاعب',
  '/owners': 'الملاك',
  '/users': 'المستخدمون',
};

export function RequireAdmin() {
  const { isAdmin } = useAuth();
  if (!isAdmin) return <Navigate to="/login" replace />;
  return <Outlet />;
}

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const pageTitle = titles[location.pathname] || (location.pathname.startsWith('/owners/') ? 'تفاصيل المالك' : 'الإدارة');

  return (
    <div className="min-h-screen lg:grid lg:grid-cols-[272px_1fr]">
      <aside className="relative border-b border-pitch-800/40 bg-pitch-950 text-pitch-50 lg:min-h-screen lg:border-b-0 lg:border-l">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(500px_240px_at_50%_-20%,rgba(94,163,111,0.25),transparent_70%)]" />
        <div className="relative px-5 py-6">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-pitch-700 shadow-lg shadow-pitch-950/40">
              <Shield className="h-6 w-6" />
            </div>
            <div>
              <p className="text-xl font-bold tracking-tight">رياضة</p>
              <p className="text-xs text-pitch-300">مركز تشغيل المنصة</p>
            </div>
          </div>
        </div>

        <nav className="relative flex gap-1 overflow-x-auto px-3 pb-4 lg:flex-col lg:overflow-visible">
          {links.map(({ to, end, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold whitespace-nowrap transition ${
                  isActive
                    ? 'bg-white text-pitch-950 shadow-sm'
                    : 'text-pitch-200 hover:bg-pitch-900 hover:text-white'
                }`
              }
            >
              <Icon className="h-4 w-4 shrink-0" />
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="relative mt-auto hidden border-t border-pitch-800/80 px-5 py-4 lg:block">
          <div className="rounded-2xl bg-pitch-900/80 px-3 py-3">
            <p className="text-sm font-semibold">{user?.name}</p>
            <p className="truncate text-xs text-pitch-400">{user?.email}</p>
            <span className="mt-2 inline-flex rounded-md bg-pitch-700 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-pitch-50">
              Admin
            </span>
          </div>
          <button type="button" onClick={handleLogout} className="btn mt-3 w-full !bg-pitch-900 !text-pitch-100 hover:!bg-pitch-800">
            <LogOut className="h-4 w-4" />
            تسجيل الخروج
          </button>
        </div>
      </aside>

      <div className="min-w-0">
        <header className="sticky top-0 z-20 flex items-center justify-between border-b border-pitch-200/70 bg-white/85 px-4 py-3.5 backdrop-blur-md lg:px-8">
          <div>
            <p className="text-sm font-bold text-pitch-950">{pageTitle}</p>
            <p className="text-xs text-pitch-500">بيانات حية من الإنتاج</p>
          </div>
          <div className="flex items-center gap-2">
            <span className="hidden items-center gap-1.5 rounded-lg bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-800 sm:inline-flex">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
              Online
            </span>
            <button type="button" onClick={handleLogout} className="btn-ghost lg:hidden">
              <LogOut className="h-4 w-4" />
              خروج
            </button>
          </div>
        </header>
        <main className="px-4 py-6 lg:px-8 lg:py-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
