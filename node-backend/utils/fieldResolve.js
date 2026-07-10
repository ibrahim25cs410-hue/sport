/**
 * حل ملاعب قديمة بلا id رقمي + مواءمة معرّف Flutter الاحتياطي.
 */
const { getStore } = require('../db');
const { Counter, Field } = require('../models');

const store = () => getStore();

/** نفس خوارزمية Field._stableId في تطبيق Flutter (seed: name|phone|address). */
function flutterStableId(field) {
  const seed = `${field.name || ''}|${field.phone || ''}|${field.address || ''}`;
  let h = 0;
  for (let i = 0; i < seed.length; i += 1) {
    const c = seed.charCodeAt(i);
    h = 0x1fffffff & (h + c);
    h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
    h ^= h >> 6;
  }
  h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
  h ^= h >> 11;
  h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
  const n = Math.abs(h);
  return n === 0 ? 1 : n;
}

/** هاش قديم في dto/legacy (imul 31). */
function legacyStableId(field) {
  const seed = `${field.name || ''}|${field.phone || ''}|${field.address || ''}|${field.ownerId || ''}`;
  let h = 0;
  for (let i = 0; i < seed.length; i += 1) {
    h = Math.imul(31, h) + seed.charCodeAt(i);
    h |= 0;
  }
  return Math.abs(h) || 1;
}

function publicNumericId(field) {
  const n = Number(field.id);
  if (Number.isFinite(n) && n > 0) return n;
  return flutterStableId(field);
}

async function listActiveFields() {
  if (store().kind === 'mongodb') {
    return store().find('fields', { isActive: { $ne: false } });
  }
  return store().find('fields', (f) => f.isActive !== false);
}

/**
 * إيجاد ملعب بالمعرّف العام (id حقيقي أو هاش احتياطي من التطبيق).
 */
async function resolveField(publicId) {
  const n = Number(publicId);
  if (!Number.isFinite(n) || n <= 0) return null;

  const byId = await store().findById('fields', n);
  if (byId && byId.isActive !== false) return byId;

  const all = await listActiveFields();
  return (
    all.find((field) => {
      const real = Number(field.id);
      if (Number.isFinite(real) && real === n) return true;
      if (flutterStableId(field) === n) return true;
      if (legacyStableId(field) === n) return true;
      return false;
    }) || null
  );
}

/**
 * يمنح id رقمي دائم للملاعب القديمة في Mongo حتى ينجح الحجز والجدول.
 */
async function ensureFieldsHaveIds() {
  if (store().kind !== 'mongodb') return { fixed: 0 };

  const missing = await Field.find({
    $or: [{ id: { $exists: false } }, { id: null }],
  });

  let fixed = 0;
  for (const doc of missing) {
    const id = await Counter.nextId('fields');
    const patch = { id };
    if (doc.ownerId == null) patch.ownerId = 0;
    await Field.updateOne({ _id: doc._id }, { $set: patch });
    fixed += 1;
  }

  if (fixed > 0) {
    console.log(`✅ تم إصلاح ${fixed} ملعب بلا id`);
  }
  return { fixed };
}

module.exports = {
  flutterStableId,
  legacyStableId,
  publicNumericId,
  resolveField,
  ensureFieldsHaveIds,
  listActiveFields,
};
