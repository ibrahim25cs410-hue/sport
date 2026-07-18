import { createContext, useContext, useMemo, useState, useCallback, useEffect } from 'react';
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

  const acceptInvitation = useCallback(async (token, password) => {
    setBusy(true);
    setError('');
    try {
      const data = await api.acceptInvitation(token, password);
      if (data.user?.role !== 'admin') throw new Error('NOT_ADMIN');
      const next = { token: data.token, user: data.user };
      setSession(next);
      setSessionState(next);
      return next;
    } catch (e) {
      setError(e.message || 'INVITATION_FAILED');
      throw e;
    } finally {
      setBusy(false);
    }
  }, []);

  const logout = useCallback(() => {
    clearSession();
    setSessionState(null);
  }, []);

  useEffect(() => {
    window.addEventListener('riyada:unauthorized', logout);
    return () => window.removeEventListener('riyada:unauthorized', logout);
  }, [logout]);

  useEffect(() => {
    if (!session?.token || session.user?.permissions) return;
    let active = true;
    api.permissions().then((data) => {
      if (!active) return;
      const next = {
        ...session,
        user: {
          ...session.user,
          permissions: data.permissions || [],
          availablePermissions: data.availablePermissions || [],
          adminRole: data.adminRole || session.user.adminRole,
        },
      };
      setSession(next);
      setSessionState(next);
    }).catch((requestError) => {
      if (!active || requestError?.status === 404) return;
      const next = { ...session, user: { ...session.user, permissions: [] } };
      setSession(next);
      setSessionState(next);
      // Only a missing endpoint indicates a legacy server; authorization failures are restrictive.
    });
    return () => { active = false; };
  }, [session]);

  const hasPermission = useCallback((permission) => {
    const permissions = session?.user?.permissions;
    return Array.isArray(permissions)
      && (permissions.includes('*') || permissions.includes(permission));
  }, [session]);

  const value = useMemo(() => ({
    session,
    user: session?.user || null,
    isAdmin: session?.user?.role === 'admin',
    busy,
    error,
    login,
    acceptInvitation,
    logout,
    hasPermission,
    setError,
  }), [session, busy, error, login, acceptInvitation, logout, hasPermission]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth outside provider');
  return ctx;
}
