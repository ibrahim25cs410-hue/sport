/* eslint-disable no-console */
const { spawn } = require('child_process');
const path = require('path');

const port = 31987;
const base = `http://127.0.0.1:${port}/api`;
const suffix = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
let token = '';

async function request(route, { method = 'GET', body, expected = 200, auth = true } = {}) {
  const response = await fetch(`${base}${route}`, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(auth && token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  let payload;
  try { payload = text ? JSON.parse(text) : null; } catch { payload = text; }
  if (response.status !== expected) {
    throw new Error(`${method} ${route}: expected ${expected}, got ${response.status}: ${text}`);
  }
  return payload;
}

async function waitForServer() {
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      const response = await fetch(`${base}/health`);
      if (response.ok) return;
    } catch { /* startup */ }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error('server did not start');
}

async function run() {
  const child = spawn(process.execPath, ['server.js'], {
    cwd: path.resolve(__dirname, '..'),
    env: {
      ...process.env,
      PORT: String(port),
      MONGODB_URI: '',
      JWT_SECRET: 'admin-smoke-test-secret-at-least-32-characters',
      ADMIN_EMAIL: `admin-${suffix}@example.test`,
      ADMIN_PASSWORD: 'admin-pass-123',
      ADMIN_NAME: 'Smoke Admin',
      ADMIN_BOOTSTRAP_SECRET: 'smoke-bootstrap-secret',
      NODE_ENV: 'test',
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let logs = '';
  child.stdout.on('data', (chunk) => { logs += chunk; });
  child.stderr.on('data', (chunk) => { logs += chunk; });

  try {
    await waitForServer();
    const login = await request('/login', {
      method: 'POST',
      auth: false,
      body: {
        email: `admin-${suffix}@example.test`,
        password: 'admin-pass-123',
        expectedRole: 'admin',
      },
    });
    token = login.token;
    const adminToken = token;
    if (!token || !login.user.permissions?.includes('bookings.manual')) {
      throw new Error('admin login did not include effective permissions');
    }

    const ownerRegistration = await request('/register-owner', {
      method: 'POST',
      auth: false,
      expected: 201,
      body: {
        name: 'Smoke Owner',
        email: `owner-${suffix}@example.test`,
        password: 'owner-pass',
        phone: '07000000000',
        stadiumName: 'Smoke Field',
        stadiumAddress: 'Test',
        pricePerHour: 10000,
      },
    });
    const userRegistration = await request('/register-user', {
      method: 'POST',
      auth: false,
      expected: 201,
      body: {
        name: 'Smoke User',
        email: `user-${suffix}@example.test`,
        password: 'user-pass',
        phone: '07111111111',
      },
    });
    const limitedAdminRegistration = await request('/register-user', {
      method: 'POST',
      auth: false,
      expected: 201,
      body: {
        name: 'Limited Admin',
        email: `limited-${suffix}@example.test`,
        password: 'limited-pass',
      },
    });
    await request('/admin/bootstrap', {
      method: 'POST',
      auth: false,
      body: {
        email: limitedAdminRegistration.user.email,
        secret: 'smoke-bootstrap-secret',
      },
    });
    const customRole = await request('/admin/roles', {
      method: 'POST',
      expected: 201,
      body: { name: 'Dashboard only', permissions: ['dashboard.read'] },
    });
    await request(`/admin/staff/${limitedAdminRegistration.user.id}`, {
      method: 'PATCH',
      body: { roleId: customRole.id },
    });
    const limitedLogin = await request('/login', {
      method: 'POST',
      auth: false,
      body: {
        email: limitedAdminRegistration.user.email,
        password: 'limited-pass',
        expectedRole: 'admin',
      },
    });
    token = limitedLogin.token;
    await request('/admin/preferences', {
      method: 'PUT',
      body: { locale: 'ar', theme: 'light' },
    });
    await request('/admin/financials', { expected: 403 });
    token = adminToken;
    await request(`/admin/roles/${customRole.id}`, {
      method: 'PUT',
      body: { permissions: ['dashboard.read', 'analytics.read'] },
    });
    token = limitedLogin.token;
    await request('/admin/analytics/dashboard');
    token = adminToken;
    await request(`/admin/staff/${limitedAdminRegistration.user.id}`, {
      method: 'PATCH',
      body: { status: 'suspended' },
    });
    token = limitedLogin.token;
    await request('/admin/permissions', { expected: 403 });
    token = adminToken;
    await request(`/admin/staff/${limitedAdminRegistration.user.id}`, {
      method: 'PATCH',
      body: { status: 'active' },
    });

    await request('/admin/preferences', {
      method: 'PUT',
      body: { locale: 'en', timezone: 'Asia/Baghdad', theme: 'dark' },
    });

    const start = new Date(Date.now() + 72 * 3600000);
    start.setUTCMinutes(0, 0, 0);
    const booking = await request('/admin/bookings/manual', {
      method: 'POST',
      expected: 201,
      body: {
        fieldId: ownerRegistration.field.id,
        userId: userRegistration.user.id,
        startTime: start.toISOString(),
        hours: 2,
        paymentMethod: 'cash',
      },
    });
    await request(`/admin/bookings/${booking.id}`);
    const rescheduledStart = new Date(start.getTime() + 3 * 3600000);
    await request(`/admin/bookings/${booking.id}/reschedule`, {
      method: 'POST',
      body: { startTime: rescheduledStart.toISOString(), reason: 'Smoke reschedule' },
    });

    await request('/admin/bookings/bulk', {
      method: 'POST',
      body: { bookingIds: [booking.id], action: 'mark_paid' },
    });
    await request('/admin/bookings/bulk', {
      method: 'POST',
      body: { bookingIds: [booking.id], action: 'mark_paid' },
    });

    const maintenanceStart = new Date(start.getTime() + 24 * 3600000);
    const maintenance = await request('/admin/maintenance-blocks', {
      method: 'POST',
      expected: 201,
      body: {
        fieldId: ownerRegistration.field.id,
        startTime: maintenanceStart.toISOString(),
        endTime: new Date(maintenanceStart.getTime() + 2 * 3600000).toISOString(),
        reason: 'Smoke maintenance',
        recurrence: 'daily',
        recurrenceEnd: new Date(maintenanceStart.getTime() + 2 * 86400000).toISOString(),
      },
    });
    await request('/admin/bookings/manual', {
      method: 'POST',
      expected: 409,
      body: {
        fieldId: ownerRegistration.field.id,
        userId: userRegistration.user.id,
        startTime: maintenanceStart.toISOString(),
        hours: 1,
      },
    });
    await request('/admin/bookings/manual', {
      method: 'POST',
      expected: 409,
      body: {
        fieldId: ownerRegistration.field.id,
        userId: userRegistration.user.id,
        startTime: new Date(maintenanceStart.getTime() + 86400000).toISOString(),
        hours: 1,
      },
    });
    await request(`/admin/maintenance-blocks/${maintenance.id}`, {
      method: 'PATCH',
      body: { reason: 'Updated recurring maintenance' },
    });
    const weeklyStart = new Date(maintenanceStart.getTime() + 4 * 3600000);
    const weeklyMaintenance = await request('/admin/maintenance-blocks', {
      method: 'POST',
      expected: 201,
      body: {
        fieldId: ownerRegistration.field.id,
        startTime: weeklyStart.toISOString(),
        endTime: new Date(weeklyStart.getTime() + 3600000).toISOString(),
        reason: 'Weekly smoke maintenance',
        recurrence: 'weekly',
        recurrenceEnd: new Date(weeklyStart.getTime() + 14 * 86400000).toISOString(),
      },
    });

    const normalStart = new Date(start.getTime() + 10 * 86400000);
    token = userRegistration.token;
    const normalBooking = await request('/bookings', {
      method: 'POST',
      expected: 201,
      body: {
        fieldId: ownerRegistration.field.id,
        startTime: normalStart.toISOString(),
        hours: 1,
        paymentMethod: 'cash',
      },
    });
    token = adminToken;
    await request(`/admin/maintenance-blocks/${maintenance.id}`, {
      method: 'PATCH',
      expected: 409,
      body: { recurrenceEnd: new Date(normalStart.getTime() + 86400000).toISOString() },
    });
    await request('/bookings/approve', {
      method: 'POST',
      body: { bookingId: normalBooking.id },
    });
    await request('/bookings/pay/verify', {
      method: 'POST',
      body: { bookingId: normalBooking.id },
    });
    const resolvedBookingAlerts = await request(
      `/admin/alerts?status=resolved&entityType=booking&entityId=${normalBooking.id}`,
    );
    if (!resolvedBookingAlerts.items.some((item) => item.type === 'booking'
      && item.actionUrl === `/bookings/${normalBooking.id}`)) {
      throw new Error('normal booking durable alert lifecycle failed');
    }
    const paymentAlerts = await request(
      `/admin/alerts?status=open&type=finance&entityType=booking&entityId=${normalBooking.id}`,
    );
    if (!paymentAlerts.items.length) throw new Error('payment alert missing');
    await request(`/fields/${ownerRegistration.field.id}`, {
      method: 'PUT',
      body: { name: 'Smoke Field Updated' },
    });
    await request(`/admin/fields/${ownerRegistration.field.id}/toggle`, { method: 'PATCH' });
    await request(`/admin/fields/${ownerRegistration.field.id}/toggle`, { method: 'PATCH' });
    await request('/admin/wallets/top-up', {
      method: 'POST',
      body: { ownerId: ownerRegistration.user.id, amount: 1000, note: 'Smoke top-up' },
    });

    const filteredBookings = await request(
      `/admin/bookings?from=${encodeURIComponent(start.toISOString())}`
      + `&to=${encodeURIComponent(normalStart.toISOString())}`
      + '&paymentStatus=paid&minAmount=9000&maxAmount=20000&sort=amount&order=asc&page=1&limit=1',
    );
    if (filteredBookings.totalCount !== 2 || filteredBookings.items.length !== 1
      || filteredBookings.items[0].totalPrice !== 10000) {
      throw new Error(`booking filters failed: ${JSON.stringify(filteredBookings)}`);
    }

    const settlement = await request('/admin/settlements', {
      method: 'POST',
      expected: 201,
      body: {
        ownerId: ownerRegistration.user.id,
        amountIqd: 5000,
        idempotencyKey: `smoke-${suffix}`,
      },
    });
    await request(`/admin/settlements/${settlement.id}`);
    await request(`/admin/settlements/${settlement.id}`, {
      method: 'PATCH',
      expected: 409,
      body: { status: 'paid' },
    });
    await request(`/admin/settlements/${settlement.id}`, {
      method: 'PATCH',
      body: { status: 'approved', approvalNote: 'Reviewed' },
    });
    const paidSettlement = await request(`/admin/settlements/${settlement.id}`, {
      method: 'PATCH',
      body: {
        status: 'paid',
        evidenceUrl: '/evidence/smoke.pdf',
        evidenceNote: 'Bank transfer',
        paymentEvidence: { reference: 'BANK-SMOKE' },
      },
    });
    if (!paidSettlement.approvedAt || !paidSettlement.paidAt || !paidSettlement.paymentEvidence) {
      throw new Error('settlement approval/evidence fields missing');
    }
    await request(`/admin/settlements/${settlement.id}`, {
      method: 'PATCH',
      expected: 409,
      body: { status: 'void', voidReason: 'not allowed' },
    });
    const alert = await request('/admin/alerts', {
      method: 'POST',
      expected: 201,
      body: {
        type: 'smoke',
        severity: 'info',
        title: 'Smoke',
        message: 'OK',
        actionUrl: `/bookings/${booking.id}`,
        entityType: 'booking',
        entityId: booking.id,
        assignedTo: limitedAdminRegistration.user.id,
        snoozeUntil: new Date(Date.now() + 3600000).toISOString(),
      },
    });
    const snoozed = await request(
      `/admin/alerts?includeSnoozed=true&assignedTo=${limitedAdminRegistration.user.id}`
      + `&entityType=booking&entityId=${booking.id}`,
    );
    if (!snoozed.items.some((item) => item.id === alert.id && item.status === 'snoozed'
      && item.actionUrl && item.assignedTo === limitedAdminRegistration.user.id)) {
      throw new Error('alert metadata/filtering failed');
    }
    await request(`/admin/alerts/${alert.id}`, {
      method: 'PATCH',
      body: { status: 'dismissed' },
    });
    await request(`/admin/alerts/${alert.id}/read`, { method: 'PATCH' });
    await request('/admin/alerts/read-all', { method: 'PATCH' });
    const roles = await request('/admin/roles');
    if (!roles.items.some((role) => role.id === 'support')) throw new Error('default roles missing');
    await request('/admin/staff/invitations', {
      method: 'POST',
      expected: 201,
      body: { name: 'Invited Admin', email: `staff-${suffix}@example.test`, roleId: 'support' },
    });
    const staff = await request('/admin/staff');
    if (!staff.items.some((item) => item.status === 'invited')) throw new Error('staff invitation missing');
    const search = await request('/admin/search?q=Smoke');
    if (!search.items.length) throw new Error('global search returned no results');
    const realtime = await request('/admin/realtime/token');
    if (!realtime.token) throw new Error('realtime token missing');
    const realtimeController = new AbortController();
    const realtimeResponse = await fetch(
      `${base}/admin/realtime/events?token=${encodeURIComponent(realtime.token)}`,
      { signal: realtimeController.signal },
    );
    if (!realtimeResponse.ok) throw new Error('realtime stream failed');
    const realtimeReader = realtimeResponse.body.getReader();
    await realtimeReader.read(); // connected event
    await request(`/admin/fields/${ownerRegistration.field.id}/toggle`, { method: 'PATCH' });
    const realtimeChunk = await Promise.race([
      realtimeReader.read(),
      new Promise((_, reject) => setTimeout(() => reject(new Error('realtime event timeout')), 2000)),
    ]);
    const realtimeText = new TextDecoder().decode(realtimeChunk.value);
    if (!realtimeText.includes('field.toggled')) throw new Error(`root realtime event missing: ${realtimeText}`);
    realtimeController.abort();
    await request(`/admin/fields/${ownerRegistration.field.id}/toggle`, { method: 'PATCH' });

    const analytics = await request('/admin/analytics');
    const dashboardAnalytics = await request('/admin/analytics/dashboard');
    const report = await request('/admin/reports/financials');
    const formattedReport = await request('/admin/reports?type=revenue');
    const audits = await request('/admin/audit-logs');
    const calendar = await request('/admin/calendar');
    const wallet = await request(`/admin/owners/${ownerRegistration.user.id}/wallet`);

    if (analytics.summary.realizedRevenueIqd !== 30000) throw new Error('realized revenue mismatch');
    if (dashboardAnalytics.realizedRevenue !== 30000) throw new Error('dashboard analytics mismatch');
    if (!formattedReport.columns.length) throw new Error('formatted report columns missing');
    if (report.expectedRevenueIqd !== 30000 || report.realizedRevenueIqd !== 30000) {
      throw new Error('financial report mismatch');
    }
    if (!audits.items.length) throw new Error('audit log is empty');
    if (calendar.maintenance.filter((item) => item.maintenanceBlockId === maintenance.id).length !== 3) {
      throw new Error('calendar missing maintenance block');
    }
    if (calendar.maintenance.filter((item) => item.maintenanceBlockId === weeklyMaintenance.id).length !== 3) {
      throw new Error('calendar missing weekly maintenance expansion');
    }
    if (!calendar.items.some((item) => item.type === 'booking')) throw new Error('calendar items missing booking');
    const bookingCredits = wallet.transactions.filter((item) => item.bookingId === booking.id);
    if (bookingCredits.length !== 2 || wallet.balance !== 28000) {
      throw new Error(`idempotent wallet credit mismatch: ${JSON.stringify(wallet)}`);
    }

    const csvResponse = await fetch(`${base}/admin/reports/financials?format=csv`, {
      headers: { authorization: `Bearer ${token}` },
    });
    if (!csvResponse.ok || !String(csvResponse.headers.get('content-type')).includes('text/csv')) {
      throw new Error('CSV export failed');
    }
    const prepared = await request('/admin/reports/exports', {
      method: 'POST',
      expected: 201,
      body: { type: 'bookings', format: 'csv' },
    });
    const preparedResponse = await fetch(`http://127.0.0.1:${port}${prepared.downloadUrl}`);
    if (!preparedResponse.ok || !String(preparedResponse.headers.get('content-type')).includes('text/csv')) {
      throw new Error('prepared CSV download failed');
    }
    for (const format of ['xlsx', 'pdf']) {
      const clientExport = await request('/admin/reports/exports', {
        method: 'POST',
        body: { type: 'bookings', format },
      });
      if (clientExport.generation !== 'client' || !Array.isArray(clientExport.rows)
        || !Array.isArray(clientExport.columns)) {
        throw new Error(`${format} export contract failed`);
      }
    }
    console.log('admin backend smoke: PASS');
  } finally {
    child.kill();
    await new Promise((resolve) => {
      child.once('exit', resolve);
      setTimeout(resolve, 1000);
    });
    if (child.exitCode && child.exitCode !== 0) console.error(logs);
  }
}

run().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
