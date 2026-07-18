/* eslint-disable no-console */
require('dotenv').config();
const mongoose = require('mongoose');
const { buildModels } = require('../backend/mongo-models');

const mode = process.argv.includes('--apply') ? 'apply'
  : (process.argv.includes('--rollback') ? 'rollback' : 'dry-run');

function slotKeys(booking) {
  const start = new Date(booking.startTime);
  const hours = Math.max(1, Number(booking.hours) || 1);
  if (Number.isNaN(start.getTime()) || !booking.fieldPublicId) return [];
  return Array.from({ length: hours }, (_, offset) => (
    `${Number(booking.fieldPublicId)}:${new Date(start.getTime() + offset * 3600000).toISOString()}`
  ));
}

async function run() {
  if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI is required');
  mongoose.set('sanitizeFilter', true);
  await mongoose.connect(process.env.MONGODB_URI);
  const models = buildModels(mongoose);
  const report = { mode, indexes: [], bookingClaims: 0, ledgerMarkers: 0, conflicts: [] };

  if (mode === 'rollback') {
    const [claimResult, markerResult] = await Promise.all([
      models.bookingClaims.deleteMany({ reservationId: 'migration:v1' }),
      models.paymentCredits.deleteMany({ migrationId: 'production-v1', legacy: true }),
    ]);
    report.bookingClaimsRemoved = claimResult.deletedCount;
    report.ledgerMarkersRemoved = markerResult.deletedCount;
    console.log(JSON.stringify(report, null, 2));
    return;
  }

  const activeBookings = await models.bookings.find({
    status: { $in: ['pending', 'approved', 'completed'] },
  }).lean();
  const seen = new Map();
  const claims = [];
  for (const booking of activeBookings) {
    for (const slotKey of slotKeys(booking)) {
      if (seen.has(slotKey)) {
        report.conflicts.push({ slotKey, bookingIds: [seen.get(slotKey), booking.id] });
      } else {
        seen.set(slotKey, booking.id);
        claims.push({ slotKey, bookingId: booking.id, reservationId: 'migration:v1' });
      }
    }
  }
  report.bookingClaims = claims.length;

  const credited = await models.bookings.find({ walletCredited: true, id: { $exists: true } }).lean();
  const existingKeys = new Set((await models.paymentCredits.find({
    idempotencyKey: { $in: credited.map((booking) => `booking:${booking.id}:paid:v1`) },
  }).lean()).map((item) => item.idempotencyKey));
  const markers = credited.filter((booking) => !existingKeys.has(`booking:${booking.id}:paid:v1`))
    .map((booking) => ({
      idempotencyKey: `booking:${booking.id}:paid:v1`,
      bookingId: booking.id,
      ownerId: booking.ownerId || null,
      grossAmountIqd: Number(booking.totalPrice) || 0,
      commissionRate: 0.10,
      status: 'completed',
      legacy: true,
      migrationId: 'production-v1',
      createdAt: booking.createdAt || new Date().toISOString(),
      completedAt: booking.walletCreditedAt || new Date().toISOString(),
    }));
  report.ledgerMarkers = markers.length;

  if (mode === 'apply') {
    if (report.conflicts.length) throw new Error('Existing booking conflicts must be resolved before apply');
    for (const model of [...Object.values(models)]) await model.createIndexes();
    report.indexes = ['created/verified'];
    if (claims.length) {
      await models.bookingClaims.bulkWrite(claims.map((claim) => ({
        updateOne: { filter: { slotKey: claim.slotKey }, update: { $setOnInsert: claim }, upsert: true },
      })), { ordered: false });
    }
    if (markers.length) await models.paymentCredits.insertMany(markers, { ordered: false });
  }
  console.log(JSON.stringify(report, null, 2));
}

if (require.main === module) {
  run().catch((error) => {
    console.error(error.stack || error);
    process.exitCode = 1;
  }).finally(() => mongoose.disconnect());
}

module.exports = { run, slotKeys };
