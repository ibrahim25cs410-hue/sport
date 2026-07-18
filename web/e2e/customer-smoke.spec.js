import { expect, test } from '@playwright/test';

test('customer login works with mocked API', async ({ page }) => {
  await page.route('**/api/**', (route) => route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ items: [], notifications: [] }),
  }));
  await page.route('**/api/login', (route) => route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ token: 'user-token', user: { id: 7, role: 'user', name: 'Test User' } }),
  }));
  await page.goto('/app/#/login');
  await page.getByLabel('البريد الإلكتروني').fill('user@example.test');
  await page.getByLabel('كلمة المرور').fill('password');
  await page.getByRole('button', { name: 'دخول' }).click();
  await expect(page).toHaveURL(/\/app\/#\/home$/);
});

test('booking surface states cash payment only', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('riyada_session', JSON.stringify({
    token: 'user-token',
    role: 'user',
    user: { id: 7, role: 'user', name: 'Test User' },
  })));
  await page.route('**/api/fields/1/review-eligibility', (route) => route.fulfill({
    status: 200, contentType: 'application/json', body: JSON.stringify({ canReview: false }),
  }));
  await page.route('**/api/fields/1/schedule', (route) => route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({
      id: 1,
      name: 'Test Field',
      pricePerHour: 10000,
      schedule: [{ date: '2026-07-20', slots: [{ startTime: '2026-07-20T17:00:00.000Z', endTime: '2026-07-20T18:00:00.000Z', isAvailable: true, status: 'available' }] }],
    }),
  }));
  await page.route('**/api/slots/select', (route) => route.fulfill({ status: 200, contentType: 'application/json', body: '{}' }));
  await page.goto('/app/#/stadium/1');
  await page.getByRole('button', { name: /1 ساعة/ }).click();
  await expect(page.getByText(/الدفع في الملعب/)).toBeVisible();
  await expect(page.getByText(/بطاقة|محفظة/)).toHaveCount(0);
});
