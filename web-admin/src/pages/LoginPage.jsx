import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { Shield } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export default function LoginPage() {
  const { login, busy, error, isAdmin, setError } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  if (isAdmin) return <Navigate to="/" replace />;

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    try {
      await login(email.trim(), password);
    } catch {
      /* shown via context */
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center px-4 py-10">
      <div className="w-full max-w-md">
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-pitch-800 text-white shadow-panel">
            <Shield className="h-7 w-7" />
          </div>
          <h1 className="text-3xl font-bold tracking-tight text-pitch-950">رياضة</h1>
          <p className="mt-2 text-sm text-pitch-600">دخول لوحة إدارة المنصة — نينوى</p>
        </div>

        <form onSubmit={onSubmit} className="panel p-6">
          <label className="label" htmlFor="email">البريد الإلكتروني</label>
          <input
            id="email"
            className="input mb-4"
            type="email"
            autoComplete="username"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />

          <label className="label" htmlFor="password">كلمة المرور</label>
          <input
            id="password"
            className="input mb-4"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />

          {error ? (
            <div className="mb-4 rounded-xl bg-red-50 px-3 py-2 text-sm text-red-700">{error}</div>
          ) : null}

          <button type="submit" className="btn-primary w-full" disabled={busy}>
            {busy ? 'جاري الدخول...' : 'دخول الإدارة'}
          </button>
        </form>

        <p className="mt-4 text-center text-xs text-pitch-500">
          الحساب يجب أن يكون بدور admin على نفس سيرفر المنصة
        </p>
      </div>
    </div>
  );
}
