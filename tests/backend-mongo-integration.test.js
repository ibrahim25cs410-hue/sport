const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const path = require('node:path');
const { spawn } = require('node:child_process');
const mongoose = require('mongoose');

const sourceUri = String(process.env.MONGODB_TEST_URI || '').trim();

function isolatedMongoUri(uri, databaseName) {
  if (!/^mongodb(\+srv)?:\/\//i.test(uri)) {
    throw new Error('MONGODB_TEST_URI must be a mongodb:// or mongodb+srv:// URI');
  }
  const queryIndex = uri.indexOf('?');
  const withoutQuery = queryIndex === -1 ? uri : uri.slice(0, queryIndex);
  const query = queryIndex === -1 ? '' : uri.slice(queryIndex);
  const authorityStart = withoutQuery.indexOf('://') + 3;
  const pathStart = withoutQuery.indexOf('/', authorityStart);
  const authority = pathStart === -1 ? withoutQuery : withoutQuery.slice(0, pathStart);
  return `${authority}/${databaseName}${query}`;
}

async function stopChild(child) {
  if (!child || child.exitCode != null) return;
  child.kill();
  await new Promise((resolve) => {
    child.once('exit', resolve);
    setTimeout(resolve, 3000);
  });
}

if (!sourceUri) {
  test('Mongo replica-set API concurrency', { skip: 'MONGODB_TEST_URI is not configured' }, () => {});
} else {
  test('Mongo replica-set API concurrency', { timeout: 120000 }, async () => {
    const databaseName = `riyada_it_${Date.now()}_${crypto.randomBytes(5).toString('hex')}`;
    assert.match(databaseName, /^riyada_it_[0-9]+_[a-f0-9]{10}$/);
    const testUri = isolatedMongoUri(sourceUri, databaseName);
    const port = 32000 + crypto.randomInt(1000, 7000);
    const base = `http://127.0.0.1:${port}/api`;
    let child;
    let logs = '';

    async function api(route, { method = 'GET', token, body, headers = {} } = {}) {
      const response = await fetch(`${base}${route}`, {
        method,
        headers: {
          'content-type': 'application/json',
          ...(token ? { authorization: `Bearer ${token}` } : {}),
          ...headers,
        },
        body: body == null ? undefined : JSON.stringify(body),
      });
      const text = await response.text();
      let payload;
      try { payload = text ? JSON.parse(text) : null; } catch { payload = text; }
      return { response, payload };
    }

    async function waitUntilReady() {
      for (let attempt = 0; attempt < 150; attempt += 1) {
        if (child.exitCode != null) throw new Error(`server exited during startup:\n${logs}`);
        try {
          const result = await api('/ready');
          if (result.response.status === 200) return result.payload;
        } catch { /* startup */ }
        await new Promise((resolve) => setTimeout(resolve, 200));
      }
      throw new Error(`Mongo API did not become ready:\n${logs}`);
    }

    try {
      const topologyConnection = await mongoose.createConnection(testUri, {
        serverSelectionTimeoutMS: 15000,
      }).asPromise();
      try {
        assert.equal(topologyConnection.name, databaseName);
        const hello = await topologyConnection.db.admin().command({ hello: 1 });
        assert.ok(
          hello.setName || hello.msg === 'isdbgrid',
          'MONGODB_TEST_URI must target a replica set or transaction-capable mongos',
        );
      } finally {
        await topologyConnection.close();
      }

      child = spawn(process.execPath, ['server.js'], {
        cwd: path.resolve(__dirname, '..'),
        env: {
          ...process.env,
          PORT: String(port),
          NODE_ENV: 'test',
          MONGODB_URI: testUri,
          JWT_SECRET: 'mongo-integration-test-secret-at-least-32-characters',
          ADMIN_EMAIL: '',
          ADMIN_PASSWORD: '',
          ADMIN_BOOTSTRAP_SECRET: '',
          ELECTRONIC_PAYMENTS_ENABLED: 'false',
        },
        stdio: ['ignore', 'pipe', 'pipe'],
      });
      child.stdout.on('data', (chunk) => { logs += String(chunk); });
      child.stderr.on('data', (chunk) => { logs += String(chunk); });

      const ready = await waitUntilReady();
      assert.equal(ready.ready, true);
      assert.equal(ready.storage, 'mongodb');
      assert.deepEqual(ready.missingIndexes, []);
      assert.equal(ready.indexError, null);

      const suffix = `${Date.now()}-${crypto.randomBytes(3).toString('hex')}`;
      const owner = await api('/register-owner', {
        method: 'POST',
        body: {
          name: 'Mongo Test Owner',
          email: `owner-${suffix}@integration.test`,
          password: 'password-123',
          stadiumName: 'Mongo Replica Field',
          pricePerHour: 10000,
        },
      });
      assert.equal(owner.response.status, 201, JSON.stringify(owner.payload));
      const user = await api('/register-user', {
        method: 'POST',
        body: {
          name: 'Mongo Test User',
          email: `user-${suffix}@integration.test`,
          password: 'password-123',
        },
      });
      assert.equal(user.response.status, 201, JSON.stringify(user.payload));

      const start = new Date(Date.now() + 10 * 86400000);
      start.setUTCMinutes(0, 0, 0);
      const bookingBody = {
        fieldId: owner.payload.field.id,
        startTime: start.toISOString(),
        hours: 2,
        paymentMethod: 'cash',
      };
      const races = await Promise.all(Array.from({ length: 12 }, (_, index) => api('/bookings', {
        method: 'POST',
        token: user.payload.token,
        body: bookingBody,
        headers: { 'idempotency-key': `mongo-race-${suffix}-${index}` },
      })));
      assert.equal(races.filter((result) => result.response.status === 201).length, 1);
      assert.equal(races.filter((result) => result.response.status === 409).length, 11);
      assert.equal(new Set(
        races.filter((result) => result.response.status === 201).map((result) => result.payload.id),
      ).size, 1);

      const replayStart = new Date(start.getTime() + 4 * 3600000).toISOString();
      const replayKey = `mongo-replay-${suffix}`;
      const first = await api('/bookings', {
        method: 'POST',
        token: user.payload.token,
        body: { ...bookingBody, startTime: replayStart, hours: 1 },
        headers: { 'idempotency-key': replayKey },
      });
      const replay = await api('/bookings', {
        method: 'POST',
        token: user.payload.token,
        body: { ...bookingBody, startTime: replayStart, hours: 1 },
        headers: { 'idempotency-key': replayKey },
      });
      assert.equal(first.response.status, 201, JSON.stringify(first.payload));
      assert.equal(replay.response.status, 201, JSON.stringify(replay.payload));
      assert.equal(replay.payload.id, first.payload.id);
      assert.equal(replay.payload.idempotentReplay, true);
      assert.equal(replay.response.headers.get('idempotent-replayed'), 'true');
    } finally {
      await stopChild(child);
      // The test always replaces any database path from MONGODB_TEST_URI with its own generated
      // riyada_it_* database and verifies that exact name again before destructive cleanup.
      if (!databaseName.startsWith('riyada_it_')) {
        throw new Error(`Refusing unsafe cleanup for database ${databaseName}`);
      }
      const cleanup = await mongoose.createConnection(testUri, {
        serverSelectionTimeoutMS: 15000,
      }).asPromise();
      try {
        assert.equal(cleanup.name, databaseName, 'cleanup connection selected an unexpected database');
        await cleanup.dropDatabase();
      } finally {
        await cleanup.close();
      }
    }
  });
}

module.exports = { isolatedMongoUri };
