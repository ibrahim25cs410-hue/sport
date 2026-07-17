import { Navigate, Outlet, NavLink, useNavigate } from 'react-router-dom';
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

export function RequireAdmin() {
  const { isAdmin } = useAuth();
  if (!isAdmin) return <Navigate to="/login" replace />;
  return <Outlet />;
}

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="min-h-screen lg:grid lg:grid-cols-[260px_1fr]">
      <aside className="border-b border-pitch-200/80 bg-pitch-950 text-pitch-50 lg:border-b-0 lg:border-l lg:min-h-screen">
        <div className="px-5 py-6">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-pitch-700">
              <Shield className="h-5 w-5" />
            </div>
            <div>
              <p className="text-lg font-bold tracking-tight">رياضة</p>
              <p className="text-xs text-pitch-300">لوحة إدارة المنصة</p>
            </div>
          </div>
        </div>

        <nav className="flex gap-1 overflow-x-auto px-3 pb-4 lg:flex-col lg:overflow-visible">
          {links.map(({ to, end, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold whitespace-nowrap transition ${
                  isActive
                    ? 'bg-pitch-700 text-white'
                    : 'text-pitch-200 hover:bg-pitch-900 hover:text-white'
                }`
              }
            >
              <Icon className="h-4 w-4 shrink-0" />
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="mt-auto hidden border-t border-pitch-800 px-5 py-4 lg:block">
          <p className="text-sm font-semibold">{user?.name}</p>
          <p className="text-xs text-pitch-400">{user?.email}</p>
          <button type="button" onClick={handleLogout} className="btn-ghost mt-3 w-full !bg-pitch-900 !text-pitch-100">
            <LogOut className="h-4 w-4" />
            تسجيل الخروج
          </button>
        </div>
      </aside>

      <div className="min-w-0">
        <header className="sticky top-0 z-20 flex items-center justify-between border-b border-pitch-200/70 bg-white/80 px-4 py-3 backdrop-blur lg:px-8">
          <div>
            <p className="text-sm font-bold text-pitch-900">إدارة المنصة مباشرة</p>
            <p className="text-xs text-pitch-600">متصل بـ sports-x7v7.onrender.com</p>
          </div>
          <button type="button" onClick={handleLogout} className="btn-ghost lg:hidden">
            <LogOut className="h-4 w-4" />
            خروج
          </button>
        </header>
        <main className="px-4 py-6 lg:px-8 lg:py-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
