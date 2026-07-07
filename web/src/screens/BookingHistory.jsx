import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { History, Clock } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useBookingHistory, useUserStats } from '../hooks/useRiyadaData';
import Header from '../components/Header';
import Badge from '../components/Badge';
import { HistoryListSkeleton } from '../components/Skeleton';
import { formatDateTime, formatMoney } from '../api';

const FILTERS = [
  { key: 'all', label: 'الكل' },
  { key: 'pending', label: 'بانتظار الموافقة' },
  { key: 'approved', label: 'مؤكدة' },
  { key: 'completed', label: 'مكتمل' },
  { key: 'cancelled', label: 'ملغي' },
];

function statusAccent(status, endTime) {
  if (status === 'pending') return 'border-r-amber-500';
  if (status === 'approved' && new Date(endTime) > new Date()) return 'border-r-green-500';
  if (status === 'approved') return 'border-r-brand-600';
  if (status === 'cancelled' || status === 'rejected') return 'border-r-gray-400';
  return 'border-r-brand-500';
}

export default function BookingHistory() {
  const navigate = useNavigate();
  const { session } = useAuth();
  const [filter, setFilter] = useState('all');
  const { data: bookings = [], isLoading, refetch } = useBookingHistory();
  const { data: stats } = useUserStats();

  const filtered = bookings.filter((b) => {
    const now = new Date();
    if (filter === 'pending') return b.status === 'pending';
    if (filter === 'approved') return b.status === 'approved' && new Date(b.endTime) > now;
    if (filter === 'completed') return b.status === 'approved' && new Date(b.endTime) <= now;
    if (filter === 'cancelled') return b.status === 'cancelled' || b.status === 'rejected';
    return true;
  });

  if (isLoading && !bookings.length) return <HistoryListSkeleton />;

  return (
    <div className="app-shell min-h-screen pb-8">
      <Header title="سجل الحجوزات" onBack={() => navigate('/home')} />

      <div className="px-5 -mt-2">
        <div className="card mb-4 gradient-hero text-white !p-5">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-white/15 flex items-center justify-center">
              <Clock className="w-6 h-6" />
            </div>
            <div>
              <p className="text-sm text-white/80">إجمالي الساعات التي حجزتها</p>
              <p className="text-2xl font-extrabold">{stats?.totalHoursBooked ?? 0} ساعة</p>
            </div>
          </div>
        </div>

        <div className="flex gap-2 mb-4 overflow-x-auto no-scrollbar">
          {FILTERS.map((f) => (
            <button
              key={f.key}
              type="button"
              onClick={() => setFilter(f.key)}
              className={`px-3 py-1.5 rounded-full text-sm whitespace-nowrap ${
                filter === f.key ? 'bg-brand-600 text-white' : 'bg-white border border-gray-200 text-gray-600'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>

        <button type="button" onClick={() => refetch()} className="text-sm text-brand-600 mb-3 flex items-center gap-1">
          <History className="w-4 h-4" /> تحديث
        </button>

        {filtered.length === 0 ? (
          <p className="text-center text-gray-400 py-12">لا توجد حجوزات</p>
        ) : (
          <div className="space-y-3">
            {filtered.map((b) => (
              <div key={b.id} className={`card border-r-4 ${statusAccent(b.status, b.endTime)}`}>
                <div className="flex justify-between items-start mb-2">
                  <Badge status={b.status} />
                  <h3 className="font-bold">{b.fieldName}</h3>
                </div>
                {b.referenceCode && <p className="text-xs text-brand-600 font-bold mb-1">{b.referenceCode}</p>}
                <p className="text-sm text-gray-600">{formatDateTime(b.startTime)}</p>
                <p className="font-bold text-brand-600 mt-2">
                  {b.hours} ساعة — {formatMoney(b.totalPrice)}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
