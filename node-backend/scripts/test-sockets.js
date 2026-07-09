/**
 * Real-time notification tests (Socket.io).
 * Usage: node scripts/test-sockets.js
 */

const { spawn } = require('child_process');
const path = require('path');
const { io } = require('socket.io-client');

const PORT = 3995;
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

function connectSocket(token) {
  return new Promise((resolve, reject) => {
    const socket = io(`http://127.0.0.1:${PORT}`, {
      auth: { token },
      transports: ['websocket'],
      reconnection: false,
    });
    socket.on('connect', () => resolve(socket));
    socket.on('connect_error', reject);
    setTimeout(() => reject(new Error('Socket connect timeout')), 5000);
  });
}

function waitForEvent(socket, event) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timeout waiting for ${event}`)), 8000);
    socket.once(event, (payload) => {
      clearTimeout(timer);
      resolve(payload);
    });
  });
}

async function runTests() {
  console.log('\n=== 1. Register owner & user ===');
  let r = await req('POST', '/auth/register', {
    body: { name: 'Socket Owner', email: 'socket-owner@test.com', password: 'secret123', role: 'owner' },
  });
  const ownerToken = r.data.token;

  r = await req('POST', '/auth/register', {
    body: { name: 'Socket User', email: 'socket-user@test.com', password: 'secret123', role: 'user' },
  });
  const userToken = r.data.token;

  console.log('\n=== 2. Connect sockets ===');
  const ownerSocket = await connectSocket(ownerToken);
  const userSocket = await connectSocket(userToken);
  assert(ownerSocket.connected && userSocket.connected, 'both sockets connected');

  console.log('\n=== 3. Owner creates stadium ===');
  r = await req('POST', '/stadiums', {
    token: ownerToken,
    body: { name: 'Socket Arena', address: 'Live St' },
  });
  const stadiumId = r.data.id;

  console.log('\n=== 4. Real-time: owner notified on new booking ===');
  const ownerNotifPromise = waitForEvent(ownerSocket, 'notification');
  const slot = futureSlot(8, 10);
  r = await req('POST', '/bookings', {
    token: userToken,
    body: { stadiumId, ...slot },
  });
  assert(r.status === 201, 'booking created');
  const bookingId = r.data.id;
  const ownerNotif = await ownerNotifPromise;
  assert(ownerNotif.title === 'New booking request', 'owner received real-time notification');

  console.log('\n=== 5. Real-time: user notified on confirm ===');
  const userNotifPromise = waitForEvent(userSocket, 'notification');
  r = await req('PATCH', `/bookings/${bookingId}/status`, {
    token: ownerToken,
    body: { status: 'confirmed' },
  });
  assert(r.status === 200 && r.data.status === 'confirmed', 'booking confirmed');
  const userNotif = await userNotifPromise;
  assert(userNotif.title === 'Booking confirmed', 'user received real-time confirmation');

  ownerSocket.disconnect();
  userSocket.disconnect();
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
