import { render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { PermissionGate, RequirePermission } from './PermissionGate';

let allowed = false;
vi.mock('../context/AuthContext', () => ({ useAuth: () => ({ hasPermission: () => allowed }) }));
vi.mock('../context/LocaleContext', () => ({ useLocale: () => ({ locale: 'en' }) }));

describe('permission gates', () => {
  beforeEach(() => { allowed = false; });

  it('hides unauthorized actions', () => {
    render(<PermissionGate permission="settlements.manage"><button>Pay</button></PermissionGate>);
    expect(screen.queryByRole('button', { name: 'Pay' })).not.toBeInTheDocument();
  });

  it('redirects unauthorized routes', () => {
    render(
      <MemoryRouter initialEntries={['/reports']}>
        <Routes>
          <Route path="/reports" element={<RequirePermission permission="finance.read">secret</RequirePermission>} />
          <Route path="/forbidden" element={<p>denied</p>} />
        </Routes>
      </MemoryRouter>,
    );
    expect(screen.getByText('denied')).toBeInTheDocument();
  });

  it('renders authorized content', () => {
    allowed = true;
    render(<PermissionGate permission="alerts.manage"><button>Resolve</button></PermissionGate>);
    expect(screen.getByRole('button', { name: 'Resolve' })).toBeVisible();
  });
});
