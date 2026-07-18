const test = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const path = require('node:path');

const port = 31988;
const base = `http://127.0.0.1:${port}/api`;
let child;

async function wait() {
  for (let i = 0; i < 80; i += 1) {
    try {
      if ((await fetch(`${base}/ready`)).ok) return;
    } catch { /* starting */ }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error('backend did not become ready');
}

async function json(route, { method = 'GET', token, body, headers = {} } = {}) {
  const response = await fetch(`${base}${route}`, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
    body: body == null ? undefined : JSON.stringify(body),
  });
  const payload = await response.json();
  return { response, payload };
}

test.before(async () => {
  child = spawn(process.execPath, ['server.js'], {
    cwd: path.resolve(__dirname, '..'),
    env: {
      ...process.env,
      PORT: String(port),
      NODE_ENV: 'test',
      MONGODB_URI: '',
      JWT_SECRET: 'backend-api-test-secret-at-least-32-characters',
      ELECTRONIC_PAYMENTS_ENABLED: 'false',
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  await wait();
});

test.after(async () => {
  child.kill();
  await new Promise((resolve) => {
    child.once('exit', resolve);
    setTimeout(resolve, 1000);
  });
});

test('readiness and request IDs are exposed', async () => {
  const ready = await fetch(`${base}/ready`, { headers: { 'x-request-id': 'test-request-123' } });
  assert.equal(ready.status, 200);
  assert.equal(ready.headers.get('x-request-id'), 'test-request-123');
  assert.equal((await ready.json()).storage, 'memory');
});

test('booking creation is atomic, idempotent, cash-only, and RBAC protected', async () => {
  const suffix = Date.now();
  const owner = await json('/register-owner', {
    method: 'POST',
    body: {
      name: 'Owner', email: `owner-${suffix}@test.example`, password: 'password-123',
      stadiumName: 'Atomic Field', pricePerHour: 10000,
    },
  });
  assert.equal(owner.response.status, 201);
  const user = await json('/register-user', {
    method: 'POST',
    body: { name: 'User', email: `user-${suffix}@test.example`, password: 'password-123' },
  });
  assert.equal(user.response.status, 201);
  const token = user.payload.token;
  const start = new Date(Date.now() + 7 * 86400000);
  start.setUTCMinutes(0, 0, 0);
  const body = {
    fieldId: owner.payload.field.id, startTime: start.toISOString(), hours: 2, paymentMethod: 'card',
  };

  const races = await Promise.all(Array.from({ length: 12 }, (_, index) => json('/bookings', {
    method: 'POST', token, body, headers: { 'idempotency-key': `race-${suffix}-${index}` },
  })));
  assert.equal(races.filter(({ response }) => response.status === 201).length, 1);
  assert.equal(races.filter(({ response }) => response.status === 409).length, 11);
  const winner = races.find(({ response }) => response.status === 201).payload;
  assert.equal(winner.paymentMethod, 'cash');
  assert.equal(winner.paymentStatus, 'pay_at_venue');

  const secondStart = new Date(start.getTime() + 4 * 3600000).toISOString();
  const repeated = await Promise.all(Array.from({ length: 8 }, () => json('/bookings', {
    method: 'POST',
    token,
    body: { ...body, startTime: secondStart, hours: 1 },
    headers: { 'idempotency-key': `same-${suffix}` },
  })));
  assert.ok(repeated.every(({ response }) => response.status === 201));
  assert.equal(new Set(repeated.map(({ payload }) => payload.id)).size, 1);
  assert.equal(repeated.filter(({ payload }) => payload.idempotentReplay === false).length, 1);

  const pay = await json(`/bookings/${winner.id}/pay/initiate`, { method: 'POST', token, body: {} });
  assert.equal(pay.response.status, 503);
  assert.equal(pay.payload.code, 'ELECTRONIC_PAYMENTS_DISABLED');

  const forbidden = await json('/admin/stats', { token });
  assert.equal(forbidden.response.status, 403);
});
