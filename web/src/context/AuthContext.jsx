import { createContext, useContext, useState, useEffect } from 'react';
import { storage } from '../api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setSession(storage.getSession());
    setLoading(false);
  }, []);

  const login = (data) => {
    const s = { token: data.token, user: data.user, stadium: data.stadium ?? data.field, role: data.user.role };
    storage.saveSession(s);
    setSession(s);
    return s;
  };

  const logout = () => {
    storage.clearSession();
    setSession(null);
  };

  return (
    <AuthContext.Provider value={{ session, loading, login, logout, setSession }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
