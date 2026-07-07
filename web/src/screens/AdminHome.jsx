import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Users, Building2, Calendar, Wallet, Shield, ToggleLeft, ToggleRight, LogOut,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import {
  useAdminStats,
  useAdminFinancials,
  useAdminOwners,
  useAdminFields,
  useAdminPendingBookings,
  useAdminToggleField,
  useAdminTopUp,
} from '../hooks/useAdminData';
import Header from '../components/Header';
import Button from '../components/Button';
import EmptyState from '../components/EmptyState';
import { formatMoney } from '../api';

function StatBox({ icon: Icon, label, value, color = 'brand' }) {
  const colors = {
    brand: 'from-brand-500 to-brand-600',
    amber: 'from-amber-400 to-amber-500',
    blue: 'from-blue-400 to-blue-500',
  };
  return (
    <div className="card !p-4 text-center">
      <div className={`w-11 h-11 mx-auto rounded-xl bg-gradient-to-br ${colors[color]} flex items-center justify-center mb-2`}>
        <Icon className="w-5 h-5 text-white" />
      </div>
      <p className="text-xs text-gray-500">{label}</p>
      <p className="font-extrabold text-lg">{value}</p>
    </div>
  );
}

export default function AdminHome() {
  const navigate = useNavigate();
  const { logout } = useAuth();
  const [tab, setTab] = useState('dashboard');
  const [topUpOwner, setTopUpOwner] = useState(null);
  const [amount, setAmount] = useState('');

  const stats = useAdminStats();
  const financials = useAdminFinancials();
  const owners = useAdminOwners();
  const fields = useAdminFields();
  const pending = useAdminPendingBookings();
  const toggleField = useAdminToggleField();
  const topUp = useAdminTopUp();

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const tabs = [
    { id: 'dashboard', label: 'لوحة التحكم' },
    { id: 'fields', label: 'الملاعب' },
    { id: 'owners', label: 'الملاك' },
    { id: 'pending', label: 'حجوزات معلقة' },
  ];

  return (
    <div className="app-shell min-h-screen pb-8 animate-fade-in">
      <Header title="لوحة الإدارة" subtitle="رياضة — نينوى" onLogout={handleLogout} />

      <div className="px-5 flex gap-2 overflow-x-auto pb-3">
        {tabs.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => setTab(t.id)}
            className={`shrink-0 px-4 py-2 rounded-full text-sm font-bold transition-colors ${
              tab === t.id ? 'bg-brand-600 text-white' : 'bg-gray-100 text-gray-600'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div className="px-5">
        {tab === 'dashboard' && (
          <div>
            {stats.isLoading ? (
              <p className="text-center text-gray-400 py-12">جاري التحميل...</p>
            ) : stats.error ? (
              <EmptyState icon={Shield} title="تعذّر تحميل الإحصائيات" onAction={() => stats.refetch()} />
            ) : (
              <>
                <div className="grid grid-cols-2 gap-3 mb-4">
                  <StatBox icon={Users} label="المستخدمون" value={stats.data?.totalUsers ?? 0} />
                  <StatBox icon={Building2} label="أصحاب الملاعب" value={stats.data?.totalOwners ?? 0} color="amber" />
                  <StatBox icon={Calendar} label="الملاعب" value={stats.data?.totalFields ?? 0} color="blue" />
                  <StatBox icon={Calendar} label="الحجوزات" value={stats.data?.totalBookings ?? 0} />
                </div>
                <div className="card border-r-4 border-r-brand-500">
                  <p className="text-sm text-gray-500 mb-1">إيرادات المنصة</p>
                  <p className="text-2xl font-extrabold text-brand-700">
                    {formatMoney(financials.data?.platformCommissionIqd ?? stats.data?.platformCommissionIqd ?? 0)}
                  </p>
                </div>
              </>
            )}
          </div>
        )}

        {tab === 'fields' && (
          <div className="space-y-3">
            {fields.isLoading ? (
              <p className="text-center text-gray-400 py-12">جاري التحميل...</p>
            ) : (
              (fields.data ?? []).map((f) => (
                <div key={f.id} className="card flex items-center justify-between gap-3">
                  <div className="text-right flex-1">
                    <p className="font-bold text-brand-700">{f.name}</p>
                    <p className="text-sm text-gray-500">{f.ownerName} — {f.address}</p>
                  </div>
                  <button
                    type="button"
                    onClick={() => toggleField.mutate(f.id)}
                    className="flex items-center gap-1 text-sm font-semibold"
                  >
                    {f.isActive ? (
                      <><ToggleRight className="w-6 h-6 text-green-600" /> نشط</>
                    ) : (
                      <><ToggleLeft className="w-6 h-6 text-gray-400" /> معطّل</>
                    )}
                  </button>
                </div>
              ))
            )}
          </div>
        )}

        {tab === 'owners' && (
          <div className="space-y-3">
            {(owners.data ?? []).map((o) => (
              <div key={o.id} className="card">
                <p className="font-bold">{o.name}</p>
                <p className="text-sm text-gray-500">{o.email} — {o.phone}</p>
                <p className="text-xs text-gray-400 mt-1">{o.fieldCount} ملعب</p>
                <Button
                  className="mt-3 !py-2 text-sm"
                  onClick={() => { setTopUpOwner(o); setAmount('50000'); }}
                >
                  <Wallet className="w-4 h-4" /> شحن محفظة
                </Button>
              </div>
            ))}
          </div>
        )}

        {tab === 'pending' && (
          <div className="space-y-3">
            {(pending.data ?? []).length === 0 ? (
              <EmptyState icon={Calendar} title="لا توجد حجوزات معلقة" />
            ) : (
              (pending.data ?? []).map((b) => (
                <div key={b.id} className="card">
                  <p className="font-bold text-brand-700">{b.fieldName}</p>
                  <p className="text-sm text-gray-600">{b.userName} — {b.hours} ساعة — {formatMoney(b.totalPrice)}</p>
                </div>
              ))
            )}
          </div>
        )}
      </div>

      {topUpOwner && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-black/45" onClick={() => setTopUpOwner(null)} aria-label="إغلاق" />
          <div className="relative bg-white rounded-2xl p-6 w-full max-w-sm shadow-float">
            <h3 className="font-bold text-lg mb-2">شحن محفظة {topUpOwner.name}</h3>
            <input
              type="number"
              className="input-field w-full mb-4"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />
            <div className="flex gap-3">
              <Button variant="secondary" className="flex-1" onClick={() => setTopUpOwner(null)}>إلغاء</Button>
              <Button
                className="flex-1"
                loading={topUp.isPending}
                onClick={() => topUp.mutate(
                  { ownerId: topUpOwner.id, amount: parseInt(amount, 10), note: 'شحن من لوحة الإدارة' },
                  { onSuccess: () => setTopUpOwner(null) },
                )}
              >
                تأكيد
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
