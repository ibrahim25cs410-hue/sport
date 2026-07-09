/**
 * اختبار شامل لـ API — يشغّل السيرفر محلياً ويختبر جميع السيناريوهات.
 * الاستخدام: node scripts/test-api.js
 * مع MongoDB: MONGODB_URI=... node scripts/test-api.js
 */

const { spawn } = require('child_process');
const path = require('path');

const PORT = 3996;
const BASE = `http://127.0.0.1:${PORT}/api`;
let passed = 0;
let failed = 0;

function assert(cond, msg) {
  if (cond) { passed++; console.log(`  ✓ ${msg}`); }
  else { failed++; console.error(`  ✗ ${msg}`); }
}

async function req(method, path, { body, token } = {}) {
  const headers = { 'Content-Type': 'application/json', Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${BASE}${path}`, {
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

async function runTests() {
  console.log('\n=== 1. Health ===');
  let r = await req('GET', '/health');
  assert(r.status === 200 && r.data.status === 'ok', `health (${r.data?.storage})`);

  console.log('\n=== 2. Register user ===');
  r = await req('POST', '/register-user', {
    body: { name: 'مستخدم اختبار', email: 'testuser@riyada.test', password: 'test1234', phone: '07701234567' },
  });
  assert(r.status === 201 && r.data.token, 'register user');
  const userToken = r.data.token;
  const userId = r.data.user.id;

  console.log('\n=== 3. Register owner + field ===');
  r = await req('POST', '/register-owner', {
    body: {
      name: 'مالك اختبار', email: 'testowner@riyada.test', password: 'test1234',
      stadiumName: 'ملعب الاختبار', stadiumAddress: 'الموصل', pricePerHour: 30000,
    },
  });
  assert(r.status === 201 && r.data.field, 'register owner');
  const ownerToken = r.data.token;
  const ownerId = r.data.user.id;
  const fieldId = r.data.field.id;

  console.log('\n=== 4. Login ===');
  r = await req('POST', '/login', { body: { email: 'testuser@riyada.test', password: 'test1234' } });
  assert(r.status === 200 && r.data.token, 'login user');

  console.log('\n=== 5. List fields ===');
  r = await req('GET', '/fields?page=1&limit=20', { token: userToken });
  assert(r.status === 200 && Array.isArray(r.data.items) && r.data.items.length >= 1, 'list fields');

  console.log('\n=== 6. Update field ===');
  r = await req('PUT', `/fields/${fieldId}`, {
    token: ownerToken,
    body: { name: 'ملعب محدّث', pricePerHour: 35000 },
  });
  assert(r.status === 200 && r.data.name === 'ملعب محدّث', 'update field');

  console.log('\n=== 7. Create booking ===');
  const startTime = new Date(Date.now() + 86400000 * 3);
  startTime.setHours(15, 0, 0, 0);
  r = await req('POST', '/bookings', {
    token: userToken,
    body: { fieldId, startTime: startTime.toISOString(), hours: 2, paymentMethod: 'online' },
  });
  assert(r.status === 201 && r.data.id, 'create booking');
  const bookingId = r.data.id;

  console.log('\n=== 8. User bookings ===');
  r = await req('GET', `/bookings/user/${userId}`, { token: userToken });
  assert(r.status === 200 && r.data.items?.[0]?.status === 'pending', 'user bookings pending');

  console.log('\n=== 9. Owner dashboard ===');
  r = await req('GET', `/bookings/owner/${ownerId}`, { token: ownerToken });
  assert(r.status === 200 && r.data.pendingCount >= 1, 'owner dashboard');

  console.log('\n=== 10. Approve booking ===');
  r = await req('POST', '/bookings/approve', { token: ownerToken, body: { bookingId } });
  assert(r.status === 200, 'approve booking');

  r = await req('GET', `/bookings/user/${userId}`, { token: userToken });
  assert(r.data.items?.[0]?.status === 'approved', 'booking approved');

  console.log('\n=== 11. Notifications ===');
  r = await req('GET', `/notifications/${ownerId}`, { token: ownerToken });
  assert(r.status === 200 && r.data.items?.length >= 1, 'owner notifications');

  console.log('\n=== 12. Stats ===');
  r = await req('GET', `/stats/user/${userId}`, { token: userToken });
  assert(r.status === 200, 'user stats');

  console.log('\n=== 13. Reject flow (new booking) ===');
  const start2 = new Date(Date.now() + 86400000 * 4);
  start2.setHours(16, 0, 0, 0);
  r = await req('POST', '/bookings', {
    token: userToken,
    body: { fieldId, startTime: start2.toISOString(), hours: 1, paymentMethod: 'cash' },
  });
  const booking2 = r.data.id;
  r = await req('POST', '/bookings/reject', { token: ownerToken, body: { bookingId: booking2 } });
  assert(r.status === 200, 'reject booking');

  console.log('\n=== 14. Soft delete field ===');
  r = await req('DELETE', `/fields/${fieldId}`, { token: ownerToken });
  assert(r.status === 200, 'soft delete field');
  r = await req('GET', '/fields?page=1&limit=50', { token: userToken });
  const stillListed = r.data.items?.some((f) => f.id === fieldId);
  assert(!stillListed, 'deleted field hidden from list');

  return { userId, ownerId, fieldId, bookingId };
}

async function main() {
  const serverPath = path.join(__dirname, '..', 'server.js');
  const env = { ...process.env, PORT: String(PORT) };
  const child = spawn(process.execPath, [serverPath], { env, stdio: ['ignore', 'pipe', 'pipe'] });

  let ready = false;
  child.stdout.on('data', (d) => {
    const s = d.toString();
    if (s.includes('الخادم يعمل')) ready = true;
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
  console.log(`نتيجة: ${passed} نجح، ${failed} فشل`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });
