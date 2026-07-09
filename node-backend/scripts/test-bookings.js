/**
 * Stadium booking flow integration tests.
 * Usage: node scripts/test-bookings.js
 */

const { spawn } = require('child_process');
const path = require('path');

const PORT = 3999;
const BASE = `http://127.0.0.1:${PORT}/api`;
let passed = 0;
let failed = 0;

function assert(cond, msg) {
  if (cond) { passed++; console.log(`  ✓ ${msg}`); }
  else { failed++; console.error(`  ✗ ${msg}`); }
}

async function req(method, route, { body, token } = {}) {
  const headers = { 'Content-Type': 'application/json', Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${BASE}${route}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data;
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }
  return { status: res.status, data };
}

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

function futureSlot(daysAhead, hour) {
  const start = new Date(Date.now() + daysAhead * 86400000);
  start.setHours(hour, 0, 0, 0);
  const end = new Date(start.getTime() + 2 * 3600000);
  return { startTime: start.toISOString(), endTime: end.toISOString() };
}

async function runTests() {
  console.log('\n=== 1. Register owner ===');
  let r = await req('POST', '/auth/register', {
    body: { name: 'Booking Owner', email: 'booking-owner@test.com', password: 'secret123', role: 'owner' },
  });
  assert(r.status === 201 && r.data.token, 'register owner');
  const ownerToken = r.data.token;

  console.log('\n=== 2. Register user ===');
  r = await req('POST', '/auth/register', {
    body: { name: 'Booking User', email: 'booking-user@test.com', password: 'secret123', role: 'user' },
  });
  assert(r.status === 201 && r.data.token, 'register user');
  const userToken = r.data.token;

  console.log('\n=== 3. Owner creates stadium ===');
  r = await req('POST', '/stadiums', {
    token: ownerToken,
    body: { name: 'Olympic Arena', address: '1 Stadium Rd', pricePerHour: 40000 },
  });
  assert(r.status === 201 && r.data.id, 'create stadium');
  const stadiumId = r.data.id;

  console.log('\n=== 4. Owner cannot create booking ===');
  const slot1 = futureSlot(5, 14);
  r = await req('POST', '/bookings', {
    token: ownerToken,
    body: { stadiumId, ...slot1 },
  });
  assert(r.status === 403, 'owner blocked from booking');

  console.log('\n=== 5. User creates booking (pending) ===');
  r = await req('POST', '/bookings', {
    token: userToken,
    body: { stadiumId, ...slot1 },
  });
  assert(r.status === 201 && r.data.status === 'pending', 'user creates pending booking');
  const bookingId = r.data.id;

  console.log('\n=== 6. User views booking history ===');
  r = await req('GET', '/bookings/user/me', { token: userToken });
  assert(r.status === 200 && r.data.items?.[0]?.id === bookingId, 'user booking history');

  console.log('\n=== 7. Owner views booking requests ===');
  r = await req('GET', '/bookings/owner/me', { token: ownerToken });
  assert(r.status === 200 && r.data.pendingCount === 1, 'owner sees pending request');

  console.log('\n=== 8. Other owner cannot confirm booking ===');
  r = await req('POST', '/auth/register', {
    body: { name: 'Other Owner', email: 'other-owner@test.com', password: 'secret123', role: 'owner' },
  });
  const otherOwnerToken = r.data.token;
  r = await req('PATCH', `/bookings/${bookingId}/status`, {
    token: otherOwnerToken,
    body: { status: 'confirmed' },
  });
  assert(r.status === 403, 'foreign owner blocked');

  console.log('\n=== 9. Owner confirms booking ===');
  r = await req('PATCH', `/bookings/${bookingId}/status`, {
    token: ownerToken,
    body: { status: 'confirmed' },
  });
  assert(r.status === 200 && r.data.status === 'confirmed', 'owner confirms booking');

  console.log('\n=== 10. User sees confirmed status ===');
  r = await req('GET', '/bookings/user/me', { token: userToken });
  assert(r.data.items?.[0]?.status === 'confirmed', 'user sees confirmed status');

  console.log('\n=== 11. Reject flow on second booking ===');
  const slot2 = futureSlot(6, 16);
  r = await req('POST', '/bookings', {
    token: userToken,
    body: { stadiumId, ...slot2 },
  });
  const booking2Id = r.data.id;
  r = await req('PATCH', `/bookings/${booking2Id}/status`, {
    token: ownerToken,
    body: { status: 'rejected' },
  });
  assert(r.status === 200 && r.data.status === 'rejected', 'owner rejects booking');

  console.log('\n=== 12. Notifications created ===');
  const ownerMe = await req('GET', '/auth/me', { token: ownerToken });
  const userMe = await req('GET', '/auth/me', { token: userToken });
  r = await req('GET', `/notifications/${ownerMe.data.user.id}`, { token: ownerToken });
  assert(r.status === 200 && r.data.items?.length >= 1, 'owner received notifications');
  r = await req('GET', `/notifications/${userMe.data.user.id}`, { token: userToken });
  assert(r.status === 200 && r.data.items?.length >= 1, 'user received status notifications');

  console.log('\n=== 13. Inactive stadium cannot be booked ===');
  r = await req('POST', '/stadiums', {
    token: ownerToken,
    body: { name: 'Temp Ground', address: 'Side St' },
  });
  const tempStadiumId = r.data.id;
  await req('DELETE', `/stadiums/${tempStadiumId}`, { token: ownerToken });
  const slot3 = futureSlot(7, 11);
  r = await req('POST', '/bookings', {
    token: userToken,
    body: { stadiumId: tempStadiumId, ...slot3 },
  });
  assert(r.status === 404, 'inactive stadium rejected');
}

async function main() {
  const serverPath = path.join(__dirname, '..', 'server.js');
  const env = { ...process.env, PORT: String(PORT) };
  const child = spawn(process.execPath, [serverPath], { env, stdio: ['ignore', 'pipe', 'pipe'] });

  let ready = false;
  child.stdout.on('data', (d) => {
    if (d.toString().includes('الخادم يعمل')) ready = true;
  });
  child.stderr.on('data', (d) => process.stderr.write(d));

  for (let i = 0; i < 30 && !ready; i++) await sleep(500);
  if (!ready) { console.error('Server failed to start'); child.kill(); process.exit(1); }

  try {
    await runTests();
  } finally {
    child.kill();
  }

  console.log(`\n${'='.repeat(40)}`);
  console.log(`Result: ${passed} passed, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });
