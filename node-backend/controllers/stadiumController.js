const { getStore } = require('../db');
const { publicStadium } = require('../utils/dto');
const { serverError } = require('../utils/errors');

const DUPLICATE_STADIUM_MSG = 'Stadium already exists under your account, please login to update it';

const store = () => getStore();
const isMongo = () => store().kind === 'mongodb';

const normalizeName = (name) => String(name).trim().toLowerCase();

function paged(items, page, limit) {
  return {
    items,
    page: Number(page) || 1,
    limit: Number(limit) || items.length,
    totalCount: items.length,
    hasNextPage: false,
  };
}

async function allActiveStadiums() {
  if (isMongo()) {
    return store().find('stadiums', { isActive: { $ne: false } });
  }
  return store().find('stadiums', (stadium) => stadium.isActive !== false);
}

async function stadiumsByOwner(ownerId) {
  const id = Number(ownerId);
  if (isMongo()) {
    return store().find('stadiums', { ownerId: id, isActive: { $ne: false } });
  }
  return store().find('stadiums', (stadium) => stadium.ownerId === id && stadium.isActive !== false);
}

async function findDuplicateForOwner(ownerId, name, excludeId = null) {
  const norm = normalizeName(name);
  const owned = await stadiumsByOwner(ownerId);
  return owned.find((stadium) => {
    if (excludeId != null && Number(stadium.id) === Number(excludeId)) return false;
    return normalizeName(stadium.name) === norm;
  }) || null;
}

/**
 * GET /api/stadiums — public list of active stadiums
 */
async function listStadiums(req, res) {
  try {
    const list = (await allActiveStadiums()).map(publicStadium);
    return res.json(paged(list, req.query.page, req.query.limit));
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * GET /api/stadiums/mine — stadiums owned by the authenticated owner
 */
async function listMyStadiums(req, res) {
  try {
    const list = (await stadiumsByOwner(req.user.id)).map(publicStadium);
    return res.json(paged(list, req.query.page, req.query.limit));
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * GET /api/stadiums/:id
 */
async function getStadium(req, res) {
  try {
    const stadium = await store().findById('stadiums', req.params.id);
    if (!stadium || stadium.isActive === false) {
      return res.status(404).json({ message: 'Stadium not found' });
    }
    return res.json(publicStadium(stadium));
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * POST /api/stadiums — owner only
 */
async function createStadium(req, res) {
  try {
    const { name, address, phone, image, pricePerHour, description, latitude, longitude } = req.body || {};

    if (!name || !String(name).trim()) {
      return res.status(400).json({ message: 'Stadium name is required' });
    }

    const duplicate = await findDuplicateForOwner(req.user.id, name);
    if (duplicate) {
      return res.status(409).json({ message: DUPLICATE_STADIUM_MSG });
    }

    const stadium = await store().insert('stadiums', {
      name: String(name).trim(),
      address: address || '',
      phone: phone || '',
      image: image || null,
      pricePerHour: Number(pricePerHour) || 0,
      ownerId: Number(req.user.id),
      description: description || '',
      latitude: latitude ?? null,
      longitude: longitude ?? null,
      isActive: true,
    });

    return res.status(201).json(publicStadium(stadium));
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * PUT /api/stadiums/:id — owner only, own stadium
 */
async function updateStadium(req, res) {
  try {
    const stadium = await store().findById('stadiums', req.params.id);
    if (!stadium || stadium.isActive === false) {
      return res.status(404).json({ message: 'Stadium not found' });
    }

    if (Number(stadium.ownerId) !== Number(req.user.id)) {
      return res.status(403).json({ message: 'You can only update your own stadiums' });
    }

    const { name, address, phone, image, pricePerHour, description, latitude, longitude } = req.body || {};
    const patch = {};

    if (name != null) {
      const trimmed = String(name).trim();
      if (!trimmed) return res.status(400).json({ message: 'Stadium name cannot be empty' });
      const duplicate = await findDuplicateForOwner(req.user.id, trimmed, stadium.id);
      if (duplicate) {
        return res.status(409).json({ message: DUPLICATE_STADIUM_MSG });
      }
      patch.name = trimmed;
    }
    if (address != null) patch.address = address;
    if (phone != null) patch.phone = phone;
    if (image != null) patch.image = image;
    if (pricePerHour != null) patch.pricePerHour = Number(pricePerHour);
    if (description != null) patch.description = description;
    if (latitude != null) patch.latitude = latitude;
    if (longitude != null) patch.longitude = longitude;

    const updated = await store().update('stadiums', stadium.id, patch);
    return res.json(publicStadium(updated));
  } catch (error) {
    return serverError(res, error);
  }
}

/**
 * DELETE /api/stadiums/:id — owner only, soft delete
 */
async function deleteStadium(req, res) {
  try {
    const stadium = await store().findById('stadiums', req.params.id);
    if (!stadium || stadium.isActive === false) {
      return res.status(404).json({ message: 'Stadium not found' });
    }

    if (Number(stadium.ownerId) !== Number(req.user.id)) {
      return res.status(403).json({ message: 'You can only delete your own stadiums' });
    }

    await store().softDeleteStadium(stadium.id);
    return res.json({ message: 'Stadium deleted', id: Number(stadium.id) });
  } catch (error) {
    return serverError(res, error);
  }
}

module.exports = {
  listStadiums,
  listMyStadiums,
  getStadium,
  createStadium,
  updateStadium,
  deleteStadium,
};
