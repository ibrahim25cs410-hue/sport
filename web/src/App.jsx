import { HashRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import { AuthProvider, useAuth } from './context/AuthContext';
import { SmartToastProvider } from './context/SmartToastContext';
import { storage } from './api';
import LoadingScreen from './components/LoadingScreen';
import Welcome from './screens/Welcome';
import Login from './screens/Login';
import RegisterUser from './screens/RegisterUser';
import RegisterOwner from './screens/RegisterOwner';
import UserHome from './screens/UserHome';
import StadiumDetail from './screens/StadiumDetail';
import OwnerHome from './screens/OwnerHome';
import AdminHome from './screens/AdminHome';
import BookingHistory from './screens/BookingHistory';
import Settings from './screens/Settings';
import PrivacyPolicy from './screens/PrivacyPolicy';
import { ConnectionStatus } from './components/AppQuality';

function ProtectedRoute({ children, role }) {
  const { session, loading } = useAuth();
  const effectiveSession = session ?? storage.getSession();
  if (loading) return <LoadingScreen />;
  if (!effectiveSession) return <Navigate to="/" replace />;
  if (role && effectiveSession.role !== role) {
    const dest = effectiveSession.role === 'admin' ? '/admin' : effectiveSession.role === 'owner' ? '/owner' : '/home';
    return <Navigate to={dest} replace />;
  }
  return children;
}

function AnimatedRoutes() {
  const location = useLocation();
  const { session } = useAuth();
  const effectiveSession = session ?? storage.getSession();
  return (
    <AnimatePresence mode="wait">
      <Routes location={location} key={location.pathname}>
        <Route path="/" element={effectiveSession ? <Navigate to={effectiveSession.role === 'admin' ? '/admin' : effectiveSession.role === 'owner' ? '/owner' : '/home'} replace /> : <Welcome />} />
        <Route path="/login" element={effectiveSession ? <Navigate to={effectiveSession.role === 'admin' ? '/admin' : effectiveSession.role === 'owner' ? '/owner' : '/home'} replace /> : <Login />} />
        <Route path="/register-user" element={effectiveSession?.role === 'user' ? <Navigate to="/home" replace /> : <RegisterUser />} />
        <Route path="/register-owner" element={effectiveSession?.role === 'owner' ? <Navigate to="/owner" replace /> : <RegisterOwner />} />
        <Route path="/home" element={<ProtectedRoute role="user"><UserHome /></ProtectedRoute>} />
        <Route path="/stadium/:id" element={<ProtectedRoute role="user"><StadiumDetail /></ProtectedRoute>} />
        <Route path="/owner" element={<ProtectedRoute role="owner"><OwnerHome /></ProtectedRoute>} />
        <Route path="/admin" element={<ProtectedRoute role="admin"><AdminHome /></ProtectedRoute>} />
        <Route path="/history" element={<ProtectedRoute role="user"><BookingHistory /></ProtectedRoute>} />
        <Route path="/settings" element={<ProtectedRoute><Settings /></ProtectedRoute>} />
        <Route path="/privacy" element={<PrivacyPolicy />} />
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </AnimatePresence>
  );
}

function AppRoutes() {
  const { loading } = useAuth();
  if (loading) return <LoadingScreen />;

  return <AnimatedRoutes />;
}

export default function App() {
  return (
    <HashRouter>
      <AuthProvider>
        <SmartToastProvider>
          <ConnectionStatus />
          <AppRoutes />
        </SmartToastProvider>
      </AuthProvider>
    </HashRouter>
  );
}
