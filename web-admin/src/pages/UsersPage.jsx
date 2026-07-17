import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';
import { EmptyBlock, ErrorBlock, LoadingBlock, PageHeader, StatusBadge } from '../components/ui';

export default function UsersPage() {
  const [q, setQ] = useState('');
  const [role, setRole] = useState('user');

  const users = useQuery({
    queryKey: ['admin-users', role, q],
    queryFn: () => api.users({ role, q, limit: 100 }),
  });

  const items = users.data?.items || [];

  return (
    <div>
      <PageHeader title="المستخدمون" subtitle="عرض وبحث حسابات المنصة" />

      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="flex gap-2">
          {[
            { id: 'user', label: 'مستخدمون' },
            { id: 'owner', label: 'ملاك' },
            { id: 'admin', label: 'أدمن' },
            { id: '', label: 'الكل' },
          ].map((r) => (
            <button
              key={r.id || 'all'}
              type="button"
              className={`rounded-full px-3 py-1.5 text-sm font-semibold ${
                role === r.id ? 'bg-pitch-700 text-white' : 'border border-pitch-200 bg-white text-pitch-700'
              }`}
              onClick={() => setRole(r.id)}
            >
              {r.label}
            </button>
          ))}
        </div>
        <input
          className="input max-w-sm"
          placeholder="بحث بالاسم / البريد / الهاتف"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>

      {users.isLoading ? <LoadingBlock /> : null}
      {users.isError ? <ErrorBlock error={users.error} onRetry={users.refetch} /> : null}
      {!users.isLoading && !items.length ? <EmptyBlock title="لا نتائج" /> : null}

      {items.length ? (
        <div className="panel overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-pitch-50 text-pitch-700">
              <tr>
                <th className="px-4 py-3 text-right">الاسم</th>
                <th className="px-4 py-3 text-right">البريد</th>
                <th className="px-4 py-3 text-right">الهاتف</th>
                <th className="px-4 py-3 text-right">المحافظة</th>
                <th className="px-4 py-3 text-right">الدور</th>
              </tr>
            </thead>
            <tbody>
              {items.map((u) => (
                <tr key={u.id} className="border-t border-pitch-100">
                  <td className="px-4 py-3 font-semibold">{u.name}</td>
                  <td className="px-4 py-3">{u.email}</td>
                  <td className="px-4 py-3">{u.phone || '—'}</td>
                  <td className="px-4 py-3">{u.province}</td>
                  <td className="px-4 py-3">
                    <StatusBadge status={u.role === 'admin' ? 'paid' : u.role === 'owner' ? 'active' : 'pending'} />
                    <span className="mr-2 text-xs text-pitch-500">{u.role}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </div>
  );
}
