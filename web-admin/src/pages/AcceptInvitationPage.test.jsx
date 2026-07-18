import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import AcceptInvitationPage from './AcceptInvitationPage';
import { invitationErrorKey } from '../lib/invitation';

const mocks = vi.hoisted(() => ({ acceptInvitation: vi.fn(), clearError: vi.fn() }));
vi.mock('../context/AuthContext', () => ({
  useAuth: () => ({
    acceptInvitation: mocks.acceptInvitation,
    busy: false,
    isAdmin: false,
    setError: mocks.clearError,
  }),
}));
vi.mock('../context/LocaleContext', () => ({
  useLocale: () => ({
    locale: 'en',
    toggleLocale: vi.fn(),
    t: (key) => ({
      'invitation.title': 'Activate your admin account',
      'invitation.subtitle': 'Complete invitation',
      'invitation.password': 'New password',
      'invitation.confirm': 'Confirm password',
      'invitation.submit': 'Activate account',
      'invitation.submitting': 'Activating account...',
      'invitation.passwordHint': 'Use at least 8 characters',
      'invitation.passwordShort': 'Password must contain at least 8 characters.',
      'invitation.mismatch': 'Passwords do not match.',
      'invitation.missing': 'This invitation link is incomplete.',
      'invitation.expired': 'This invitation has expired.',
      'invitation.used': 'This invitation was already used.',
      'invitation.invalid': 'This invitation link is invalid.',
      'invitation.server': 'The account could not be activated.',
      'invitation.login': 'Back to sign in',
    })[key] || key,
  }),
}));

function renderPage(entry = '/accept-invitation?token=invite-token') {
  return render(
    <MemoryRouter initialEntries={[entry]}>
      <Routes>
        <Route path="/accept-invitation" element={<AcceptInvitationPage />} />
        <Route path="/" element={<p>Panel home</p>} />
      </Routes>
    </MemoryRouter>,
  );
}

async function fillPasswords(password, confirmation = password) {
  const user = userEvent.setup();
  await user.type(screen.getByLabelText('New password'), password);
  await user.type(screen.getByLabelText('Confirm password'), confirmation);
  return user;
}

describe('AcceptInvitationPage', () => {
  beforeEach(() => vi.clearAllMocks());

  it('reports a missing invitation token accessibly', () => {
    renderPage('/accept-invitation');
    expect(screen.getByRole('alert')).toHaveTextContent('incomplete');
    expect(screen.getByRole('button', { name: 'Activate account' })).toBeDisabled();
  });

  it('validates password confirmation before submitting', async () => {
    renderPage();
    const user = await fillPasswords('password123', 'different123');
    await user.click(screen.getByRole('button', { name: 'Activate account' }));
    expect(screen.getByRole('alert')).toHaveTextContent('do not match');
    expect(mocks.acceptInvitation).not.toHaveBeenCalled();
  });

  it('maps expired and used API failures', () => {
    expect(invitationErrorKey({ status: 410 })).toBe('expired');
    expect(invitationErrorKey({ status: 409 })).toBe('used');
    expect(invitationErrorKey({ status: 500 })).toBe('server');
  });

  it('stores the accepted session through auth and redirects', async () => {
    mocks.acceptInvitation.mockResolvedValue({ token: 'session-token' });
    renderPage();
    const user = await fillPasswords('password123');
    await user.click(screen.getByRole('button', { name: 'Activate account' }));
    expect(mocks.acceptInvitation).toHaveBeenCalledWith('invite-token', 'password123');
    expect(await screen.findByText('Panel home')).toBeVisible();
  });

  it('shows an expired invitation response', async () => {
    mocks.acceptInvitation.mockRejectedValue({ status: 410 });
    renderPage();
    const user = await fillPasswords('password123');
    await user.click(screen.getByRole('button', { name: 'Activate account' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('expired');
  });
});
