const test = require('node:test');
const assert = require('node:assert/strict');
const {
  allowedOrigin, cspConfig, redact,
} = require('../backend/security');
const {
  createInvitationToken, tokenHash,
} = require('../backend/invitations');
const {
  effectivePermissions, hasPermission,
} = require('../admin-backend');
const { slotKeys } = require('../scripts/migrate-production-data');
const { Mongoose } = require('mongoose');
const { buildModels } = require('../backend/mongo-models');

test('redaction recursively removes credentials', () => {
  const value = redact({
    password: 'secret',
    headers: { authorization: 'Bearer secret' },
    nested: { token: 'secret', safe: 'ok' },
  });
  assert.equal(value.password, '[REDACTED]');
  assert.equal(value.headers.authorization, '[REDACTED]');
  assert.equal(value.nested.token, '[REDACTED]');
  assert.equal(value.nested.safe, 'ok');
});

test('production CORS is allow-list only while native clients remain supported', () => {
  assert.equal(allowedOrigin(undefined, ['https://admin.example'], true), true);
  assert.equal(allowedOrigin('https://admin.example', ['https://admin.example'], true), true);
  assert.equal(allowedOrigin('https://evil.example', ['https://admin.example'], true), false);
  assert.equal(allowedOrigin('https://admin.example', ['*'], true), false);
  assert.deepEqual(cspConfig().directives.objectSrc, ["'none'"]);
});

test('invitation tokens are random and stored only as deterministic hashes', () => {
  const first = createInvitationToken();
  const second = createInvitationToken();
  assert.notEqual(first.token, second.token);
  assert.equal(first.hash, tokenHash(first.token));
  assert.match(first.hash, /^[a-f0-9]{64}$/);
});

test('RBAC denials override role and custom grants', () => {
  const admin = {
    role: 'admin',
    adminRole: 'support',
    customPermissions: ['finance.manage'],
    deniedPermissions: ['bookings.manage'],
  };
  assert.equal(hasPermission(admin, 'finance.manage'), true);
  assert.equal(hasPermission(admin, 'bookings.manage'), false);
  assert.ok(!effectivePermissions(admin).includes('bookings.manage'));
  assert.deepEqual(effectivePermissions({ role: 'user' }), []);
});

test('migration claims every occupied hour without changing financial data', () => {
  const keys = slotKeys({
    id: 9,
    fieldPublicId: 4,
    startTime: '2026-08-01T10:00:00.000Z',
    hours: 3,
  });
  assert.deepEqual(keys, [
    '4:2026-08-01T10:00:00.000Z',
    '4:2026-08-01T11:00:00.000Z',
    '4:2026-08-01T12:00:00.000Z',
  ]);
  assert.equal(slotKeys({ fieldPublicId: 4, startTime: 'invalid', hours: 1 }).length, 0);
});

test('critical Mongo schemas reject unknown writes', () => {
  const isolated = new Mongoose();
  const models = buildModels(isolated);
  const critical = [
    'users', 'fields', 'bookings', 'walletTransactions',
    'paymentCredits', 'settlements', 'adminInvitations', 'auditLogs', 'bookingClaims',
  ];
  for (const name of critical) {
    assert.equal(models[name].schema.options.strict, 'throw', `${name} must use strict throw`);
    assert.throws(
      () => new models[name]({ unknownProductionField: true }),
      /not in schema and strict mode is set to throw/,
      `${name} accepted an unknown field`,
    );
  }
});

test('strict Mongo schemas retain known legacy API fields', () => {
  const isolated = new Mongoose();
  const models = buildModels(isolated);
  const user = new models.users({
    id: 1,
    name: 'Legacy Admin',
    email: 'LEGACY@EXAMPLE.TEST',
    password: 'hash',
    phone: '0700',
    province: 'نينوى',
    image: 'data:image/png;base64,old',
    role: 'admin',
    loyaltyPoints: 12,
    walletBalance: 500,
    walletStatus: 'active',
    adminRole: 'custom',
    customRoleId: 9,
    customPermissions: ['dashboard.read'],
    deniedPermissions: [],
    adminStatus: 'active',
    fcmToken: 'legacy-fcm',
    sessionVersion: 2,
  });
  assert.equal(user.validateSync(), undefined);
  assert.equal(user.email, 'legacy@example.test');

  const booking = new models.bookings({
    id: 2,
    fieldId: 44,
    fieldPublicId: 44,
    fieldName: 'Legacy Field',
    customerName: 'Legacy Customer',
    customerPhone: '0711',
    ownerId: 3,
    userId: 4,
    startTime: '2026-08-01T10:00:00.000Z',
    hours: 2,
    totalPrice: 20000,
    status: 'approved',
    paymentStatus: 'pay_at_venue',
    paymentMethod: 'cash',
    referenceCode: 'REF-LEGACY',
    source: 'admin',
    adminNotes: 'imported',
    walletCredited: false,
    createdAt: '2026-01-01T00:00:00.000Z',
  });
  assert.equal(booking.validateSync(), undefined);
  assert.equal(booking.fieldId, '44');

  const settlement = new models.settlements({
    id: 3,
    ownerId: 3,
    ownerName: 'Legacy Owner',
    amountIqd: 9000,
    grossAmount: 10000,
    platformFee: 1000,
    netAmount: 9000,
    status: 'paid',
    paymentEvidence: { reference: 'BANK-OLD' },
    paidAt: '2026-01-02T00:00:00.000Z',
  });
  assert.equal(settlement.validateSync(), undefined);
  assert.equal(settlement.paymentEvidence.reference, 'BANK-OLD');

  const hydrated = models.users.hydrate({
    id: 99,
    email: 'archive@example.test',
    role: 'user',
    unknownHistoricalField: { importedBy: 'old-system' },
  });
  assert.deepEqual(
    hydrated.toObject().unknownHistoricalField,
    { importedBy: 'old-system' },
    'strict writes must not strip fields already stored in legacy Mongo documents',
  );

  const migrationMarker = new models.paymentCredits({
    id: 5,
    idempotencyKey: 'booking:2:paid:v1',
    bookingId: 2,
    ownerId: 3,
    grossAmountIqd: 20000,
    commissionRate: 0.10,
    status: 'completed',
    legacy: true,
    migrationId: 'production-v1',
    createdAt: '2026-01-01T00:00:00.000Z',
    completedAt: '2026-01-01T00:00:00.000Z',
  });
  assert.equal(migrationMarker.validateSync(), undefined);
  const migrationClaim = new models.bookingClaims({
    slotKey: '44:2026-08-01T10:00:00.000Z',
    bookingId: 2,
    reservationId: 'migration:v1',
  });
  assert.equal(migrationClaim.validateSync(), undefined);
});
