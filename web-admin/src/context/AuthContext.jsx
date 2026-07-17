import { createContext, useContext, useMemo, useState, useCallback } from 'react';
import { api, clearSession, getSession, setSession } from '../lib/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [session, setSessionState] = useState(() => getSession());
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const login = useCallback(async (email, password) => {
    setBusy(true);
    setError('');
    try {
      const data = await api.login(email, password);
      if (data.user?.role !== 'admin') {
        const err = new Error('NOT_ADMIN');
        throw err;
      }
      const next = { token: data.token, user: data.user };
      setSession(next);
      setSessionState(next);
      return next;
    } catch (e) {
      setError(e.message === 'NOT_ADMIN' ? 'NOT_ADMIN' : (e.message || 'LOGIN_FAILED'));
      throw e;
    } finally {
      setBusy(false);
    }
  }, []);

  const logout = useCallback(() => {
    clearSession();
    setSessionState(null);
  }, []);

  const value = useMemo(() => ({
    session,
    user: session?.user || null,
    isAdmin: session?.user?.role === 'admin',
    busy,
    error,
    login,
    logout,
    setError,
  }), [session, busy, error, login, logout]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth outside provider');
  return ctx;
}
