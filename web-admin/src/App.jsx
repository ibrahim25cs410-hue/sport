import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import AdminLayout, { RequireAdmin } from './components/AdminLayout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import BookingsPage from './pages/BookingsPage';
import FieldsPage from './pages/FieldsPage';
import OwnersPage from './pages/OwnersPage';
import OwnerDetailPage from './pages/OwnerDetailPage';
import UsersPage from './pages/UsersPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 20_000,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter basename="/panel">
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<RequireAdmin />}>
              <Route element={<AdminLayout />}>
                <Route index element={<DashboardPage />} />
                <Route path="bookings" element={<BookingsPage />} />
                <Route path="fields" element={<FieldsPage />} />
                <Route path="owners" element={<OwnersPage />} />
                <Route path="owners/:ownerId" element={<OwnerDetailPage />} />
                <Route path="users" element={<UsersPage />} />
              </Route>
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}
