import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  MapPin, Phone, Mail, Clock, CheckCircle, XCircle,
  TrendingUp, Wallet, Percent, AlertCircle, Building2,
} from 'lucide-react';
import { formatDateTime, formatMoney } from '../api';
import { useAuth } from '../context/AuthContext';
import { useOwnerDashboard, useOwnerBookingAction } from '../hooks/useRiyadaData';
import { useLiveUpdates } from '../hooks/useLiveUpdates';
import Header from '../components/Header';
import Badge from '../components/Badge';
import Button from '../components/Button';
import EmptyState from '../components/EmptyState';
import { OwnerDashboardSkeleton } from '../components/Skeleton';

function StatCard({ icon: Icon, label, value, color }) {
  const colors = {
    green: 'from-brand-500 to-brand-600',
    amber: 'from-amber-400 to-amber-500',
    red: 'from-red-400 to-red-500',
    blue: 'from-blue-400 to-blue-500',
  };
  return (
    <div className="card !p-3 text-center">
      <div className={`w-10 h-10 mx-auto rounded-xl bg-gradient-to-br ${colors[color]} flex items-center justify-center mb-2`}>
        <Icon className="w-5 h-5 text-white" />
      </div>
      <p className="text-xs text-gray-500">{label}</p>
      <p className="font-extrabold text-sm mt-0.5">{value}</p>
    </div>
  );
}

export default function OwnerHome() {
  const navigate = useNavigate();
  const { logout } = useAuth();
  const [filter, setFilter] = useState('all');
  const { data: dashboard, isLoading, error, refetch } = useOwnerDashboard();
  const actionMutation = useOwnerBookingAction();
  useLiveUpdates(true);

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const handleAction = (bookingId, action) => {
    actionMutation.mutate({ bookingId, action });
  };

  if (isLoading && !dashboard) return <OwnerDashboardSkeleton />;

  if (error && !dashboard) {
    return (
      <div className="app-shell min-h-screen pb-8 animate-fade-in">
        <Header title="لوحة التحكم" onLogout={handleLogout} />
        <EmptyState
          icon={Building2}
          title="تعذّر تحميل لوحة التحكم"
          subtitle="تحقق من اتصالك بالإنترنت وحاول مجدداً"
          onAction={refetch}
        />
      </div>
    );
  }

  const stadium = dashboard?.field ?? dashboard?.stadium;
  const bookings = dashboard?.bookings || [];
  const filtered = filter === 'all' ? bookings : bookings.filter((b) => b.status === filter);
  const approvedCount = bookings.filter((b) => b.status === 'approved').length;

  return (
    <div className="app-shell min-h-screen pb-8 animate-fade-in">
      <Header
        title="لوحة التحكم"
        subtitle={stadium?.name}
        onLogout={handleLogout}
      />

      <div className="px-5 -mt-2">
        <div className="card mb-4 border-r-4 border-r-brand-500">
          <div className="flex items-center gap-3">
            <div className="w-14 h-14 rounded-2xl gradient-hero flex items-center justify-center">
              <Building2 className="w-7 h-7 text-white" />
            </div>
            <div className="text-right flex-1">
              <h3 className="font-bold text-lg text-brand-700">{stadium?.name}</h3>
              <p className="text-gray-500 text-sm flex items-center gap-1 justify-end">
                <MapPin className="w-3.5 h-3.5" />{stadium?.address}
              </p>
              <p className="text-gray-500 text-sm flex items-center gap-1 justify-end">
                <Phone className="w-3.5 h-3.5" />{stadium?.phone}
              </p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3 mb-5">
          <StatCard icon={TrendingUp} label="إجمالي الإيرادات" value={formatMoney(dashboard?.totalRevenue)} color="green" />
          <StatCard icon={Wallet} label="الصافي" value={formatMoney(dashboard?.netRevenue)} color="blue" />
          <StatCard icon={Percent} label="نسبة التطبيق" value={formatMoney(dashboard?.appCommission)} color="red" />
          <StatCard icon={AlertCircle} label="بانتظار الموافقة" value={dashboard?.pendingCount || 0} color="amber" />
        </div>

        <div className="card mb-5 bg-gradient-to-l from-brand-50 to-white">
          <p className="text-sm text-gray-600 text-right">
            نسبة التطبيق: <strong>2,000 د.ع</strong> لكل حجز مؤكد
            ({approvedCount} حجز × 2,000 = {formatMoney(dashboard?.appCommission)})
          </p>
        </div>

        <div className="flex gap-2 mb-4 overflow-x-auto no-scrollbar">
          {[
            { key: 'all', label: 'الكل' },
            { key: 'pending', label: 'معلّقة' },
            { key: 'approved', label: 'مؤكدة' },
            { key: 'rejected', label: 'مرفوضة' },
          ].map((f) => (
            <button
              key={f.key}
              type="button"
              onClick={() => setFilter(f.key)}
              className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
                filter === f.key
                  ? 'bg-brand-600 text-white shadow-md'
                  : 'bg-white text-gray-500 border border-gray-200'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>

        {filtered.length === 0 ? (
          <div className="text-center py-12">
            <span className="text-5xl">📋</span>
            <p className="text-gray-400 mt-4">لا توجد حجوزات</p>
          </div>
        ) : (
          <div className="space-y-3">
            {filtered.map((b) => {
              const busy = actionMutation.isPending && actionMutation.variables?.bookingId === b.id;
              return (
                <div key={b.id} className="card">
                  <div className="flex items-start justify-between mb-2">
                    <Badge status={b.status} />
                    <h3 className="font-bold text-lg">{b.userName}</h3>
                  </div>

                  <div className="space-y-1.5 text-sm text-gray-600">
                    <p className="flex items-center gap-2 justify-end"><Phone className="w-4 h-4 text-brand-500" />{b.userPhone}</p>
                    <p className="flex items-center gap-2 justify-end"><Mail className="w-4 h-4 text-brand-500" />{b.userEmail}</p>
                    <p className="flex items-center gap-2 justify-end"><Clock className="w-4 h-4 text-brand-500" />{formatDateTime(b.startTime)}</p>
                    <p className="font-bold text-brand-600 text-right">{b.hours} ساعة — {formatMoney(b.totalPrice)}</p>
                  </div>

                  {b.status === 'pending' && (
                    <div className="flex gap-2 mt-3">
                      <Button
                        variant="primary"
                        className="!py-2.5 flex-1 !text-sm"
                        loading={busy}
                        onClick={() => handleAction(b.id, 'approve')}
                      >
                        <CheckCircle className="w-4 h-4" /> موافقة
                      </Button>
                      <Button
                        variant="danger"
                        className="!py-2.5 flex-1 !text-sm"
                        loading={busy}
                        onClick={() => handleAction(b.id, 'reject')}
                      >
                        <XCircle className="w-4 h-4" /> رفض
                      </Button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
