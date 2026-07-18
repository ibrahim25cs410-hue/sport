import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { LocaleProvider } from './context/LocaleContext';
import { ThemeProvider } from './context/ThemeContext';
import { FeedbackProvider } from './context/FeedbackContext';
import AdminLayout, { RequireAdmin } from './components/AdminLayout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import BookingsPage from './pages/BookingsPage';
import FieldsPage from './pages/FieldsPage';
import OwnersPage from './pages/OwnersPage';
import OwnerDetailPage from './pages/OwnerDetailPage';
import UsersPage from './pages/UsersPage';
import SettingsPage from './pages/SettingsPage';
import { AuditLogPage } from './pages/OperationsPages';
import { EnhancedAlertsPage, EnhancedCalendarPage, EnhancedReportsPage, EnhancedSettlementsPage, EnhancedStaffPage } from './pages/EnhancedOperations';
import { BookingCreatePage, BookingDetailPage, BookingReschedulePage, MaintenancePage } from './pages/BookingWorkflowPages';
import { ForbiddenPage, RequirePermission } from './components/PermissionGate';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 20_000,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

const guarded = (permission, page) => <RequirePermission permission={permission}>{page}</RequirePermission>;

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <LocaleProvider>
          <AuthProvider>
            <FeedbackProvider>
            <BrowserRouter basename="/panel">
              <Routes>
                <Route path="/login" element={<LoginPage />} />
                <Route element={<RequireAdmin />}>
                  <Route element={<AdminLayout />}>
                    <Route index element={guarded('dashboard.read', <DashboardPage />)} />
                    <Route path="bookings" element={guarded('bookings.read', <BookingsPage />)} />
                    <Route path="bookings/new" element={guarded('bookings.manual', <BookingCreatePage />)} />
                    <Route path="bookings/:bookingId" element={guarded('bookings.read', <BookingDetailPage />)} />
                    <Route path="bookings/:bookingId/reschedule" element={guarded('bookings.manage', <BookingReschedulePage />)} />
                    <Route path="calendar" element={guarded('bookings.read', <EnhancedCalendarPage />)} />
                    <Route path="maintenance/new" element={guarded('maintenance.manage', <MaintenancePage />)} />
                    <Route path="alerts" element={guarded('alerts.read', <EnhancedAlertsPage />)} />
                    <Route path="reports" element={guarded('finance.read', <EnhancedReportsPage />)} />
                    <Route path="settlements" element={guarded('settlements.read', <EnhancedSettlementsPage />)} />
                    <Route path="staff" element={guarded('admins.manage', <EnhancedStaffPage />)} />
                    <Route path="audit-log" element={guarded('audit.read', <AuditLogPage />)} />
                    <Route path="fields" element={guarded('fields.read', <FieldsPage />)} />
                    <Route path="owners" element={guarded('finance.read', <OwnersPage />)} />
                    <Route path="owners/:ownerId" element={guarded('finance.read', <OwnerDetailPage />)} />
                    <Route path="users" element={guarded('users.read', <UsersPage />)} />
                    <Route path="settings" element={<SettingsPage />} />
                    <Route path="forbidden" element={<ForbiddenPage />} />
                  </Route>
                </Route>
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </BrowserRouter>
            </FeedbackProvider>
          </AuthProvider>
        </LocaleProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}
