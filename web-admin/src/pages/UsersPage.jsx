import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';
import { EmptyBlock, ErrorBlock, FilterChips, LoadingBlock, PageHeader, Toolbar } from '../components/ui';
import { useLocale } from '../context/LocaleContext';

export default function UsersPage() {
  const { t } = useLocale();
  const [q, setQ] = useState('');
  const [role, setRole] = useState('user');
  const users = useQuery({
    queryKey: ['admin-users', role, q],
    queryFn: () => api.users({ role, q, limit: 100 }),
  });
  const items = users.data?.items || [];

  return (
    <div>
      <PageHeader title={t('users.title')} subtitle={t('users.subtitle')} />
      <Toolbar>
        <FilterChips
          options={[
            { id: 'user', label: t('users.players') },
            { id: 'owner', label: t('users.owners') },
            { id: 'admin', label: t('users.admins') },
            { id: '', label: t('users.all') },
          ]}
          value={role}
          onChange={setRole}
        />
        <input className="input max-w-sm" placeholder={t('users.searchPh')} value={q} onChange={(e) => setQ(e.target.value)} />
      </Toolbar>

      {users.isLoading ? <LoadingBlock /> : null}
      {users.isError ? <ErrorBlock error={users.error} onRetry={users.refetch} /> : null}
      {!users.isLoading && !items.length ? <EmptyBlock title={t('users.empty')} /> : null}

      {items.length ? (
        <div className="panel overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="table-head">
              <tr>
                <th className="px-4 py-3 text-start">{t('users.name')}</th>
                <th className="px-4 py-3 text-start">{t('users.email')}</th>
                <th className="px-4 py-3 text-start">{t('users.phone')}</th>
                <th className="px-4 py-3 text-start">{t('users.province')}</th>
                <th className="px-4 py-3 text-start">{t('users.role')}</th>
              </tr>
            </thead>
            <tbody>
              {items.map((u) => (
                <tr key={u.id} className="table-row">
                  <td className="px-4 py-3 font-semibold">{u.name}</td>
                  <td className="px-4 py-3">{u.email}</td>
                  <td className="px-4 py-3">{u.phone || '—'}</td>
                  <td className="px-4 py-3">{u.province}</td>
                  <td className="px-4 py-3">
                    <span className="chip bg-pitch-100 text-pitch-900 dark:bg-pitch-900 dark:text-pitch-100">{u.role}</span>
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
