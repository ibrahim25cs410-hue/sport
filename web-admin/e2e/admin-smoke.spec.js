import { expect, test } from '@playwright/test';

const session = {
  token: 'test-token',
  user: { id: 1, role: 'admin', name: 'QA Admin', permissions: ['*'] },
};

const payloadFor = (url) => {
  if (url.includes('/calendar')) return { items: [] };
  if (url.includes('/alerts')) return { items: [] };
  if (url.includes('/reports')) return { columns: [], items: [], summary: {} };
  if (url.includes('/settlements')) return { items: [] };
  if (url.includes('/fields')) return [];
  if (url.includes('/owners')) return [];
  if (url.includes('/users')) return { items: [] };
  return { items: [] };
};

test.beforeEach(async ({ page }) => {
  await page.addInitScript((value) => {
    localStorage.setItem('riyada_admin_session', JSON.stringify(value));
    localStorage.setItem('riyada_admin_locale', 'en');
  }, session);
  await page.route('**/api/**', async (route) => {
    await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(payloadFor(route.request().url())) });
  });
});

for (const [path, heading] of [
  ['calendar', 'Operations calendar'],
  ['alerts', 'Notification center'],
  ['reports', 'Reports'],
  ['settlements', 'Settlements'],
]) {
  test(`${path} route renders with mocked API`, async ({ page }) => {
    await page.goto(path);
    await expect(page.getByRole('heading', { name: heading })).toBeVisible();
  });
}

test('cash is the only manual booking payment surface', async ({ page }) => {
  await page.goto('bookings/new');
  const payment = page.getByLabel('Payment method');
  await expect(payment).toHaveValue('cash');
  await expect(payment.locator('option')).toHaveCount(1);
});

test('login submits admin credentials and enters panel', async ({ page }) => {
  await page.addInitScript(() => localStorage.removeItem('riyada_admin_session'));
  await page.route('**/api/login', (route) => route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ token: 'new-token', user: session.user }),
  }));
  await page.goto('login');
  await page.getByLabel('Email').fill('admin@example.test');
  await page.getByLabel('Password').fill('password');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await expect(page).toHaveURL(/\/panel\/?$/);
});

test('permissions deny restricted reports', async ({ page }) => {
  await page.addInitScript(() => {
    const stored = JSON.parse(localStorage.getItem('riyada_admin_session'));
    stored.user.permissions = ['dashboard.read'];
    localStorage.setItem('riyada_admin_session', JSON.stringify(stored));
  });
  await page.goto('reports');
  await expect(page.getByRole('heading', { name: 'Access denied' })).toBeVisible();
});

test('accepts an admin invitation and creates a session', async ({ page }) => {
  await page.addInitScript(() => localStorage.removeItem('riyada_admin_session'));
  await page.route('**/api/admin/invitations/accept', async (route) => {
    expect(route.request().postDataJSON()).toEqual({ token: 'valid-invite', password: 'password123' });
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ token: 'accepted-token', user: { ...session.user, permissions: ['*'] } }),
    });
  });
  await page.goto('accept-invitation?token=valid-invite');
  await page.getByLabel('New password').fill('password123');
  await page.getByLabel('Confirm password').fill('password123');
  await page.getByRole('button', { name: 'Activate account' }).click();
  await expect(page).toHaveURL(/\/panel\/?$/);
  await expect.poll(() => page.evaluate(() => JSON.parse(localStorage.getItem('riyada_admin_session'))?.token)).toBe('accepted-token');
});

test('shows an expired invitation error', async ({ page }) => {
  await page.addInitScript(() => localStorage.removeItem('riyada_admin_session'));
  await page.route('**/api/admin/invitations/accept', (route) => route.fulfill({
    status: 410,
    contentType: 'application/json',
    body: JSON.stringify({ code: 'INVITATION_EXPIRED', message: 'expired' }),
  }));
  await page.goto('accept-invitation?token=expired-invite');
  await page.getByLabel('New password').fill('password123');
  await page.getByLabel('Confirm password').fill('password123');
  await page.getByRole('button', { name: 'Activate account' }).click();
  await expect(page.getByRole('alert')).toContainText('expired');
});
