import { useState } from 'react';
import { KeyRound, Languages, Shield } from 'lucide-react';
import { Link, Navigate, useNavigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useLocale } from '../context/LocaleContext';
import { invitationErrorKey } from '../lib/invitation';

export default function AcceptInvitationPage() {
  const { acceptInvitation, busy, isAdmin, setError: clearAuthError } = useAuth();
  const { t, locale, toggleLocale } = useLocale();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const token = params.get('token')?.trim() || '';
  const [password, setPassword] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [errorKey, setErrorKey] = useState(token ? '' : 'missing');

  if (isAdmin) return <Navigate to="/" replace />;

  const onSubmit = async (event) => {
    event.preventDefault();
    clearAuthError('');
    if (password.length < 8) {
      setErrorKey('passwordShort');
      return;
    }
    if (password !== confirmation) {
      setErrorKey('mismatch');
      return;
    }
    if (!token) {
      setErrorKey('missing');
      return;
    }
    setErrorKey('');
    try {
      await acceptInvitation(token, password);
      navigate('/', { replace: true });
    } catch (error) {
      setErrorKey(invitationErrorKey(error));
    }
  };

  const errorId = errorKey ? 'invitation-error' : undefined;
  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-12">
      <button type="button" className="btn-ghost absolute start-4 top-4 !px-3 !py-2" onClick={toggleLocale} aria-label={locale === 'ar' ? 'Switch to English' : 'التبديل إلى العربية'}>
        <Languages className="h-4 w-4" aria-hidden="true" />
        {locale === 'ar' ? 'EN' : 'ع'}
      </button>
      <section className="w-full max-w-md" aria-labelledby="invitation-title">
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-pitch-800 text-white shadow-panel dark:bg-pitch-600">
            <Shield className="h-7 w-7" aria-hidden="true" />
          </div>
          <h1 id="invitation-title" className="text-2xl font-bold text-pitch-950 dark:text-pitch-50">{t('invitation.title')}</h1>
          <p className="mt-2 text-sm text-pitch-600 dark:text-pitch-300">{t('invitation.subtitle')}</p>
        </div>

        <form className="panel p-6" onSubmit={onSubmit} noValidate>
          <label className="label" htmlFor="invitation-password">{t('invitation.password')}</label>
          <div className="relative">
            <KeyRound className="pointer-events-none absolute start-3 top-3 h-4 w-4 text-pitch-500" aria-hidden="true" />
            <input
              id="invitation-password"
              className="input mb-1 ps-9"
              type="password"
              autoComplete="new-password"
              minLength={8}
              required
              value={password}
              aria-describedby={`password-hint${errorId ? ` ${errorId}` : ''}`}
              aria-invalid={Boolean(errorKey)}
              onChange={(event) => setPassword(event.target.value)}
            />
          </div>
          <p id="password-hint" className="mb-4 text-xs text-pitch-500">{t('invitation.passwordHint')}</p>

          <label className="label" htmlFor="invitation-confirmation">{t('invitation.confirm')}</label>
          <input
            id="invitation-confirmation"
            className="input mb-4"
            type="password"
            autoComplete="new-password"
            minLength={8}
            required
            value={confirmation}
            aria-describedby={errorId}
            aria-invalid={Boolean(errorKey)}
            onChange={(event) => setConfirmation(event.target.value)}
          />

          {errorKey ? <div id="invitation-error" className="mb-4 rounded-xl bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/60 dark:text-red-200" role="alert" aria-live="assertive">{t(`invitation.${errorKey}`)}</div> : null}

          <button type="submit" className="btn-primary w-full" disabled={busy || !token}>
            {busy ? t('invitation.submitting') : t('invitation.submit')}
          </button>
          <Link to="/login" className="btn-ghost mt-3 w-full">{t('invitation.login')}</Link>
        </form>
      </section>
    </main>
  );
}
