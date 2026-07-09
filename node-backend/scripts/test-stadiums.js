/**
 * Stadium management API tests.
 * Usage: node scripts/test-stadiums.js
 */

const { spawn } = require('child_process');
const path = require('path');

const PORT = 3998;
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

async function runTests() {
  console.log('\n=== 1. Register owner ===');
  let r = await req('POST', '/auth/register', {
    body: { name: 'Stadium Owner', email: 'owner-stadium@test.com', password: 'secret123', role: 'owner' },
  });
  assert(r.status === 201 && r.data.token, 'register owner');
  const ownerToken = r.data.token;

  console.log('\n=== 2. Register regular user ===');
  r = await req('POST', '/auth/register', {
    body: { name: 'Regular User', email: 'user-stadium@test.com', password: 'secret123', role: 'user' },
  });
  assert(r.status === 201 && r.data.token, 'register user');
  const userToken = r.data.token;

  console.log('\n=== 3. User cannot create stadium ===');
  r = await req('POST', '/stadiums', {
    token: userToken,
    body: { name: 'Forbidden Arena', address: 'Main St' },
  });
  assert(r.status === 403, 'user blocked from create');

  console.log('\n=== 4. Owner creates stadium ===');
  r = await req('POST', '/stadiums', {
    token: ownerToken,
    body: { name: 'Central Arena', address: '123 Sports Ave', pricePerHour: 50000 },
  });
  assert(r.status === 201 && r.data.id, 'owner creates stadium');
  const stadiumId = r.data.id;

  console.log('\n=== 5. Duplicate stadium name for same owner ===');
  r = await req('POST', '/stadiums', {
    token: ownerToken,
    body: { name: 'central arena', address: 'Duplicate St' },
  });
  assert(
    r.status === 409 && r.data.message === 'Stadium already exists under your account, please login to update it',
    'duplicate stadium rejected',
  );

  console.log('\n=== 6. List public stadiums ===');
  r = await req('GET', '/stadiums');
  assert(r.status === 200 && r.data.items?.some((s) => s.id === stadiumId), 'public stadium list');

  console.log('\n=== 7. Owner lists own stadiums ===');
  r = await req('GET', '/stadiums/mine', { token: ownerToken });
  assert(r.status === 200 && r.data.items?.length === 1, 'owner mine list');

  console.log('\n=== 8. Owner updates stadium ===');
  r = await req('PUT', `/stadiums/${stadiumId}`, {
    token: ownerToken,
    body: { name: 'Central Arena Updated', pricePerHour: 55000 },
  });
  assert(r.status === 200 && r.data.name === 'Central Arena Updated', 'owner updates stadium');

  console.log('\n=== 9. User cannot update owner stadium ===');
  r = await req('PUT', `/stadiums/${stadiumId}`, {
    token: userToken,
    body: { name: 'Hijacked Arena' },
  });
  assert(r.status === 403, 'user blocked from update');

  console.log('\n=== 10. Owner soft-deletes stadium ===');
  r = await req('DELETE', `/stadiums/${stadiumId}`, { token: ownerToken });
  assert(r.status === 200, 'owner deletes stadium');
  r = await req('GET', '/stadiums');
  const stillListed = r.data.items?.some((s) => s.id === stadiumId);
  assert(!stillListed, 'deleted stadium hidden from public list');
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
