const crypto = require('crypto');

const ADMIN_PERMISSIONS = Object.freeze([
  'dashboard.read',
  'analytics.read',
  'users.read',
  'users.manage',
  'fields.read',
  'fields.manage',
  'bookings.read',
  'bookings.manage',
  'bookings.manual',
  'maintenance.read',
  'maintenance.manage',
  'finance.read',
  'finance.manage',
  'settlements.read',
  'settlements.manage',
  'audit.read',
  'alerts.read',
  'alerts.manage',
  'admins.manage',
  'preferences.manage',
]);

const DEFAULT_ADMIN_ROLES = Object.freeze({
  super_admin: ADMIN_PERMISSIONS,
  admin: ADMIN_PERMISSIONS, // compatibility: pre-existing admins keep full access
  operations: [
    'dashboard.read', 'analytics.read', 'users.read', 'fields.read', 'fields.manage',
    'bookings.read', 'bookings.manage', 'bookings.manual',
    'maintenance.read', 'maintenance.manage', 'alerts.read',
  ],
  finance: [
    'dashboard.read', 'analytics.read', 'users.read', 'bookings.read',
    'finance.read', 'finance.manage', 'settlements.read', 'settlements.manage',
    'audit.read', 'alerts.read',
  ],
  support: [
    'dashboard.read', 'users.read', 'bookings.read', 'bookings.manage',
    'fields.read', 'alerts.read',
  ],
  analyst: [
    'dashboard.read', 'analytics.read', 'users.read', 'fields.read',
    'bookings.read', 'finance.read', 'settlements.read', 'audit.read', 'alerts.read',
  ],
});

function sameId(a, b) {
  if (a == null || b == null) return false;
  return String(a) === String(b) || (
    Number.isFinite(Number(a)) && Number.isFinite(Number(b)) && Number(a) === Number(b)
  );
}

function validDate(value) {
  const d = value == null || value === '' ? null : new Date(value);
  return d && !Number.isNaN(d.getTime()) ? d : null;
}

function dateRange(query = {}, fallbackDays = null) {
  const now = new Date();
  const from = validDate(query.from || query.startDate)
    || (fallbackDays == null ? null : new Date(now.getTime() - fallbackDays * 86400000));
  const to = validDate(query.to || query.endDate);
  if (to && String(query.to || query.endDate || '').length <= 10) {
    to.setHours(23, 59, 59, 999);
  }
  return { from, to };
}

function inRange(value, range) {
  const d = validDate(value);
  if (!d) return false;
  return (!range.from || d >= range.from) && (!range.to || d <= range.to);
}

function csvEscape(value) {
  const text = value == null ? '' : String(value);
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function toCsv(rows, columns) {
  const header = columns.map(([key, label]) => csvEscape(label || key)).join(',');
  const lines = rows.map((row) => columns.map(([key]) => csvEscape(row[key])).join(','));
  return `\uFEFF${[header, ...lines].join('\r\n')}`;
}

function effectivePermissions(user) {
  if (!user || user.role !== 'admin') return [];
  const role = String(user.adminRole || 'admin');
  const base = DEFAULT_ADMIN_ROLES[role] || [];
  const additions = Array.isArray(user.customPermissions) ? user.customPermissions : [];
  const denials = new Set(Array.isArray(user.deniedPermissions) ? user.deniedPermissions : []);
  return [...new Set([...base, ...additions])]
    .filter((permission) => ADMIN_PERMISSIONS.includes(permission) && !denials.has(permission));
}

function hasPermission(user, permission) {
  return effectivePermissions(user).includes(permission);
}

function bookingEnd(booking) {
  const start = validDate(booking.startTime);
  return start ? new Date(start.getTime() + Math.max(1, Number(booking.hours) || 1) * 3600000) : null;
}

function bookingOverlaps(booking, start, hours) {
  const existingStart = validDate(booking.startTime);
  const existingEnd = bookingEnd(booking);
  const candidateStart = validDate(start);
  const candidateEnd = candidateStart
    ? new Date(candidateStart.getTime() + Math.max(1, Number(hours) || 1) * 3600000)
    : null;
  return !!(existingStart && existingEnd && candidateStart && candidateEnd
    && candidateStart < existingEnd && candidateEnd > existingStart);
}

function normalizeRecurrence(value) {
  const recurrence = String(value || 'none').toLowerCase();
  return ['none', 'daily', 'weekly'].includes(recurrence) ? recurrence : null;
}

function recurrenceEndDate(value) {
  const date = validDate(value);
  if (date && typeof value === 'string' && value.trim().length <= 10) {
    date.setHours(23, 59, 59, 999);
  }
  return date;
}

function expandMaintenanceBlock(block, rangeFrom = null, rangeTo = null) {
  const firstStart = validDate(block.startTime);
  const firstEnd = validDate(block.endTime);
  if (!firstStart || !firstEnd || firstEnd <= firstStart) return [];
  const recurrence = normalizeRecurrence(block.recurrence) || 'none';
  const recurrenceEnd = validDate(block.recurrenceEnd) || firstStart;
  const stepMs = recurrence === 'daily' ? 86400000 : 7 * 86400000;
  const occurrences = [];
  let occurrenceStart = firstStart;
  let index = 0;
  const hardLimit = recurrence === 'daily' ? 370 : 60;
  while (index < hardLimit) {
    if (occurrenceStart > recurrenceEnd && recurrence !== 'none') break;
    const occurrenceEnd = new Date(occurrenceStart.getTime() + (firstEnd - firstStart));
    if ((!rangeFrom || occurrenceEnd > rangeFrom) && (!rangeTo || occurrenceStart <= rangeTo)) {
      occurrences.push({
        ...block,
        occurrenceId: recurrence === 'none' ? String(block.id) : `${block.id}:${index}`,
        parentId: block.id,
        startTime: occurrenceStart.toISOString(),
        endTime: occurrenceEnd.toISOString(),
        occurrenceIndex: index,
      });
    }
    if (recurrence === 'none') break;
    occurrenceStart = new Date(occurrenceStart.getTime() + stepMs);
    index += 1;
  }
  return occurrences;
}

function setupAdminBackend(options) {
  const {
    app,
    auth,
    getStore,
    io,
    resolveField,
    publicNumericId,
    bookingBelongsToField,
    notify,
    emitBookingUpdated,
    emitToField,
    commissionRate = 0.10,
    electronicPaymentsEnabled = false,
    creditOwnerForPaidBooking,
  } = options;

  const store = () => getStore();
  const adminRoom = 'admin';
  const realtimeTokens = new Map();
  const realtimeClients = new Set();
  const reportExports = new Map();

  function publish(event, payload) {
    io.to(adminRoom).emit(event, payload);
    const message = `data: ${JSON.stringify({
      type: event.replace(/^admin:/, ''),
      event,
      payload,
      createdAt: new Date().toISOString(),
    })}\n\n`;
    for (const client of realtimeClients) client.write(message);
  }

  async function currentAdmin(req) {
    const user = await store().findById('users', req.user?.id);
    if (!user || user.role !== 'admin') return null;
    if (user.adminRole === 'custom' && user.customRoleId) {
      const role = await store().findById('adminRoles', user.customRoleId);
      if (role && role.status !== 'deleted') {
        return { ...user, customPermissions: role.permissions || [] };
      }
      return { ...user, customPermissions: [] };
    }
    return user;
  }

  function permit(permission) {
    return async (req, res, next) => {
      try {
        const user = await currentAdmin(req);
        if (!user) return res.status(403).json({ message: 'غير مصرح — للمدير فقط' });
        if (user.adminStatus === 'suspended') {
          return res.status(403).json({ message: 'الحساب الإداري موقوف' });
        }
        if (!hasPermission(user, permission)) {
          return res.status(403).json({
            message: 'لا تملك الصلاحية المطلوبة',
            requiredPermission: permission,
          });
        }
        req.admin = user;
        req.adminPermissions = effectivePermissions(user);
        return next();
      } catch (error) {
        return next(error);
      }
    };
  }

  async function audit(req, action, resourceType, resourceId, details = {}) {
    req.auditRecorded = true;
    const record = await store().insert('auditLogs', {
      actorId: Number(req.user?.id) || null,
      actorName: req.admin?.name || req.user?.name || '',
      actorEmail: req.admin?.email || req.user?.email || '',
      action,
      resourceType,
      resourceId: resourceId == null ? null : String(resourceId),
      details,
      ip: String(req.ip || ''),
      ipAddress: String(req.ip || ''),
      userAgent: String(req.headers['user-agent'] || '').slice(0, 500),
      createdAt: new Date().toISOString(),
    });
    publish('admin:audit.created', record);
    return record;
  }

  async function createAlert({
    type = 'info', severity = 'info', title, message, data = {}, dedupeKey = null,
    actionUrl = null, entityType = null, entityId = null, assignedTo = null,
    snoozeUntil = null,
  }) {
    if (dedupeKey) {
      const existing = await store().find('adminAlerts');
      const duplicate = existing.find((item) => item.dedupeKey === dedupeKey
        && ['open', 'snoozed'].includes(item.status));
      if (duplicate) return duplicate;
    }
    const normalizedActionUrl = actionUrl && String(actionUrl).startsWith('/')
      ? String(actionUrl).slice(0, 500)
      : null;
    const snoozeDate = validDate(snoozeUntil);
    const alert = await store().insert('adminAlerts', {
      type,
      severity,
      title: String(title || 'تنبيه إداري'),
      message: String(message || ''),
      data,
      dedupeKey,
      actionUrl: normalizedActionUrl,
      entityType: entityType ? String(entityType) : null,
      entityId: entityId == null ? null : String(entityId),
      assignedTo: Number.isFinite(Number(assignedTo)) && Number(assignedTo) > 0
        ? Number(assignedTo)
        : null,
      snoozeUntil: snoozeDate?.toISOString() || null,
      status: snoozeDate && snoozeDate > new Date() ? 'snoozed' : 'open',
      readBy: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
    publish('admin:alert.created', alert);
    return alert;
  }

  async function closeEntityAlerts(
    entityType, entityId, status = 'resolved', reason = 'entity_updated', alertType = null,
  ) {
    const alerts = await store().find('adminAlerts');
    const closed = [];
    for (const alert of alerts) {
      if (alert.entityType !== entityType || !sameId(alert.entityId, entityId)
        || (alertType && alert.type !== alertType)
        || !['open', 'snoozed'].includes(alert.status)) continue;
      const now = new Date().toISOString();
      const updated = await store().update('adminAlerts', alert.id, {
        status: status === 'dismissed' ? 'dismissed' : 'resolved',
        resolutionReason: reason,
        resolvedAt: status === 'dismissed' ? alert.resolvedAt || null : now,
        dismissedAt: status === 'dismissed' ? now : alert.dismissedAt || null,
        updatedAt: now,
      });
      publish('admin:alert.updated', updated);
      closed.push(updated);
    }
    return closed;
  }

  async function maintenanceConflict(field, startTime, hours, excludeId = null) {
    const start = validDate(startTime);
    if (!field || !start) return null;
    const end = new Date(start.getTime() + Math.max(1, Number(hours) || 1) * 3600000);
    const blocks = await store().find('maintenanceBlocks');
    for (const block of blocks) {
      if (block.status === 'cancelled') continue;
      if (excludeId != null && sameId(block.id, excludeId)) continue;
      if (block.fieldId != null && !sameId(block.fieldId, field.id)
        && !sameId(block.fieldId, publicNumericId(field))) continue;
      const occurrences = expandMaintenanceBlock(block, start, end);
      const occurrence = occurrences.find((item) => {
        const blockStart = validDate(item.startTime);
        const blockEnd = validDate(item.endTime);
        return blockStart && blockEnd && start < blockEnd && end > blockStart;
      });
      if (occurrence) return occurrence;
    }
    return null;
  }

  async function bookingConflict(field, startTime, hours, excludeBookingId = null) {
    const all = await store().find('bookings');
    const conflict = all.find((booking) => {
      if (excludeBookingId != null && sameId(booking.id, excludeBookingId)) return false;
      if (!['pending', 'approved', 'completed'].includes(String(booking.status))) return false;
      return bookingBelongsToField(booking, field) && bookingOverlaps(booking, startTime, hours);
    });
    if (conflict) return { type: 'booking', record: conflict };
    const block = await maintenanceConflict(field, startTime, hours);
    return block ? { type: 'maintenance', record: block } : null;
  }

  function adminBookingDto(booking, user, field) {
    return {
      id: Number(booking.id),
      referenceCode: booking.referenceCode || null,
      fieldId: Number(booking.fieldPublicId || field?.id || booking.fieldId) || 0,
      fieldName: field?.name || booking.fieldName || '',
      ownerId: Number(booking.ownerId || field?.ownerId) || 0,
      userId: Number(booking.userId) || 0,
      userName: user?.name || booking.customerName || '',
      userPhone: user?.phone || booking.customerPhone || '',
      startTime: booking.startTime,
      endTime: bookingEnd(booking)?.toISOString() || null,
      hours: Number(booking.hours) || 1,
      totalPrice: Number(booking.totalPrice) || 0,
      status: booking.status,
      paymentStatus: booking.paymentStatus || 'unpaid',
      paymentMethod: booking.paymentMethod || 'cash',
      source: booking.source || 'app',
      notes: booking.adminNotes || null,
      createdAt: booking.createdAt || null,
    };
  }

  async function hydratedBookings(query = {}) {
    const range = dateRange(query);
    const status = String(query.status || '').toLowerCase();
    const paymentStatus = String(query.paymentStatus || '').toLowerCase();
    const q = String(query.q || query.search || '').trim().toLowerCase();
    const fieldId = query.fieldId;
    const ownerId = query.ownerId;
    const userId = query.userId;
    const minAmount = query.minAmount == null || query.minAmount === '' ? null : Number(query.minAmount);
    const maxAmount = query.maxAmount == null || query.maxAmount === '' ? null : Number(query.maxAmount);
    const [bookings, users, fields] = await Promise.all([
      store().find('bookings'),
      store().find('users'),
      store().find('fields'),
    ]);
    const rows = [];
    for (const booking of bookings) {
      const field = fields.find((candidate) => bookingBelongsToField(booking, candidate));
      const user = users.find((candidate) => sameId(candidate.id, booking.userId));
      const row = adminBookingDto(booking, user, field);
      if (status && status !== 'all' && String(row.status).toLowerCase() !== status) continue;
      if (paymentStatus && String(row.paymentStatus).toLowerCase() !== paymentStatus) continue;
      if (fieldId && !sameId(row.fieldId, fieldId)) continue;
      if (ownerId && !sameId(row.ownerId, ownerId)) continue;
      if (userId && !sameId(row.userId, userId)) continue;
      if (Number.isFinite(minAmount) && row.totalPrice < minAmount) continue;
      if (Number.isFinite(maxAmount) && row.totalPrice > maxAmount) continue;
      if ((range.from || range.to) && !inRange(row.startTime, range)) continue;
      if (q) {
        const haystack = [
          row.id, row.referenceCode, row.fieldName, row.userName, row.userPhone,
        ].join(' ').toLowerCase();
        if (!haystack.includes(q)) continue;
      }
      rows.push(row);
    }
    const sortAliases = {
      date: 'startTime', startTime: 'startTime', amount: 'totalPrice', totalPrice: 'totalPrice',
      createdAt: 'createdAt', status: 'status', paymentStatus: 'paymentStatus',
      fieldName: 'fieldName', userName: 'userName', id: 'id',
    };
    const sortKey = sortAliases[query.sort] || 'startTime';
    const direction = String(query.order || 'desc').toLowerCase() === 'asc' ? 1 : -1;
    return rows.sort((a, b) => {
      const av = ['startTime', 'createdAt'].includes(sortKey)
        ? (validDate(a[sortKey])?.getTime() || 0)
        : a[sortKey];
      const bv = ['startTime', 'createdAt'].includes(sortKey)
        ? (validDate(b[sortKey])?.getTime() || 0)
        : b[sortKey];
      if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * direction;
      return String(av ?? '').localeCompare(String(bv ?? '')) * direction;
    });
  }

  function paginate(items, query = {}) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(500, Math.max(1, Number(query.limit) || 50));
    const start = (page - 1) * limit;
    return {
      items: items.slice(start, start + limit),
      page,
      limit,
      totalCount: items.length,
      hasNextPage: start + limit < items.length,
    };
  }

  app.get('/api/admin/permissions', auth, permit('dashboard.read'), async (req, res) => {
    res.json({
      permissions: req.adminPermissions,
      availablePermissions: ADMIN_PERMISSIONS,
      defaultRoles: DEFAULT_ADMIN_ROLES,
      adminRole: req.admin.adminRole || 'admin',
    });
  });

  app.get('/api/admin/realtime/token', auth, permit('alerts.read'), async (req, res) => {
    const token = crypto.randomBytes(32).toString('base64url');
    realtimeTokens.set(token, {
      adminId: Number(req.user.id),
      expiresAt: Date.now() + 60 * 1000,
    });
    res.json({ token, expiresAt: new Date(Date.now() + 60 * 1000).toISOString() });
  });

  app.get('/api/admin/realtime/events', async (req, res) => {
    const token = String(req.query.token || '');
    const grant = realtimeTokens.get(token);
    realtimeTokens.delete(token);
    if (!grant || grant.expiresAt < Date.now()) {
      return res.status(401).json({ message: 'رمز الاتصال اللحظي غير صالح' });
    }
    const admin = await store().findById('users', grant.adminId);
    if (!admin || admin.role !== 'admin' || !hasPermission(admin, 'alerts.read')) {
      return res.status(403).json({ message: 'غير مصرح' });
    }
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-transform',
      Connection: 'keep-alive',
      'X-Accel-Buffering': 'no',
    });
    res.write(`data: ${JSON.stringify({ type: 'connected', createdAt: new Date().toISOString() })}\n\n`);
    realtimeClients.add(res);
    const heartbeat = setInterval(() => res.write(': heartbeat\n\n'), 25000);
    req.on('close', () => {
      clearInterval(heartbeat);
      realtimeClients.delete(res);
    });
    return undefined;
  });

  app.get('/api/admin/admins', auth, permit('admins.manage'), async (_req, res) => {
    const users = await store().find('users');
    res.json(users.filter((user) => user.role === 'admin').map((user) => ({
      id: Number(user.id),
      name: user.name,
      email: user.email,
      adminRole: user.adminRole || 'admin',
      customPermissions: user.customPermissions || [],
      deniedPermissions: user.deniedPermissions || [],
      effectivePermissions: effectivePermissions(user),
    })));
  });

  app.patch('/api/admin/admins/:id/permissions', auth, permit('admins.manage'), async (req, res) => {
    const target = await store().findById('users', req.params.id);
    if (!target || target.role !== 'admin') return res.status(404).json({ message: 'الأدمن غير موجود' });
    const adminRole = String(req.body?.adminRole || target.adminRole || 'admin');
    if (!DEFAULT_ADMIN_ROLES[adminRole]) return res.status(400).json({ message: 'دور إداري غير صالح' });
    const customPermissions = [...new Set(
      Array.isArray(req.body?.customPermissions) ? req.body.customPermissions : [],
    )]
      .filter((permission) => ADMIN_PERMISSIONS.includes(permission));
    const deniedPermissions = [...new Set(
      Array.isArray(req.body?.deniedPermissions) ? req.body.deniedPermissions : [],
    )]
      .filter((permission) => ADMIN_PERMISSIONS.includes(permission));
    const updated = await store().update('users', target.id, {
      adminRole,
      customPermissions,
      deniedPermissions,
      permissionsUpdatedAt: new Date().toISOString(),
      permissionsUpdatedBy: Number(req.user.id),
    });
    await audit(req, 'admin.permissions.updated', 'user', target.id, {
      adminRole, customPermissions, deniedPermissions,
    });
    publish('admin:permissions.updated', { adminId: Number(target.id) });
    res.json({
      id: Number(updated.id),
      adminRole: updated.adminRole,
      customPermissions: updated.customPermissions,
      deniedPermissions: updated.deniedPermissions,
      effectivePermissions: effectivePermissions(updated),
    });
  });

  app.get('/api/admin/audit-logs', auth, permit('audit.read'), async (req, res) => {
    const range = dateRange(req.query);
    const q = String(req.query.q || '').toLowerCase();
    const action = String(req.query.action || '').toLowerCase();
    const actorId = req.query.actorId;
    let rows = await store().find('auditLogs');
    rows = rows.filter((row) => {
      if ((range.from || range.to) && !inRange(row.createdAt, range)) return false;
      if (actorId && !sameId(row.actorId, actorId)) return false;
      if (action && !String(row.action || '').toLowerCase().includes(action)) return false;
      if (q && !`${row.actorName || ''} ${row.action || ''} ${row.resourceType || ''} ${row.resourceId || ''}`
        .toLowerCase().includes(q)) return false;
      return true;
    }).sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json(paginate(rows, req.query));
  });

  app.get('/api/admin/preferences', auth, permit('dashboard.read'), async (req, res) => {
    const preferences = await store().find('adminPreferences');
    const existing = preferences.find((item) => sameId(item.adminId, req.user.id));
    res.json(existing || {
      adminId: Number(req.user.id),
      locale: 'ar',
      timezone: 'Asia/Baghdad',
      theme: 'system',
      dashboard: {},
      notifications: { enabled: true },
    });
  });

  app.put('/api/admin/preferences', auth, permit('dashboard.read'), async (req, res) => {
    const allowed = ['locale', 'timezone', 'theme', 'dashboard', 'notifications', 'defaultFilters'];
    const patch = Object.fromEntries(allowed
      .filter((key) => req.body?.[key] !== undefined)
      .map((key) => [key, req.body[key]]));
    const all = await store().find('adminPreferences');
    const existing = all.find((item) => sameId(item.adminId, req.user.id));
    const updated = existing
      ? await store().update('adminPreferences', existing.id, { ...patch, updatedAt: new Date().toISOString() })
      : await store().insert('adminPreferences', {
        adminId: Number(req.user.id), ...patch,
        createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
      });
    await audit(req, 'admin.preferences.updated', 'adminPreference', updated.id);
    res.json(updated);
  });

  app.get('/api/admin/maintenance-blocks', auth, permit('maintenance.read'), async (req, res) => {
    const range = dateRange(req.query);
    const fieldId = req.query.fieldId;
    let rows = await store().find('maintenanceBlocks');
    rows = rows.filter((row) => {
      if (fieldId && !sameId(row.fieldId, fieldId)) return false;
      if (req.query.status && row.status !== req.query.status) return false;
      if (String(req.query.upcoming || '').toLowerCase() === 'true'
        && validDate(row.recurrenceEnd || row.endTime) < new Date()) return false;
      if ((range.from || range.to)
        && expandMaintenanceBlock(row, range.from, range.to).length === 0) return false;
      return true;
    }).sort((a, b) => new Date(a.startTime) - new Date(b.startTime));
    res.json(paginate(rows, req.query));
  });

  app.post('/api/admin/maintenance-blocks', auth, permit('maintenance.manage'), async (req, res) => {
    const field = await resolveField(req.body?.fieldId);
    const start = validDate(req.body?.startTime);
    const end = validDate(req.body?.endTime);
    const recurrence = normalizeRecurrence(req.body?.recurrence);
    const recurrenceEnd = recurrenceEndDate(req.body?.recurrenceEnd);
    if (!field) return res.status(404).json({ message: 'الملعب غير موجود' });
    if (!start || !end || end <= start) return res.status(400).json({ message: 'نطاق الصيانة غير صالح' });
    if (!recurrence) return res.status(400).json({ message: 'نمط التكرار غير صالح' });
    if (recurrence !== 'none' && (!recurrenceEnd || recurrenceEnd < start
      || recurrenceEnd > new Date(start.getTime() + 366 * 86400000))) {
      return res.status(400).json({ message: 'نهاية التكرار مطلوبة ويجب ألا تتجاوز سنة' });
    }
    const draft = {
      id: 'draft',
      startTime: start.toISOString(),
      endTime: end.toISOString(),
      recurrence,
      recurrenceEnd: recurrence === 'none' ? null : recurrenceEnd.toISOString(),
    };
    const occurrences = expandMaintenanceBlock(draft);
    const activeBookings = (await store().find('bookings')).filter((booking) => {
      if (!['pending', 'approved'].includes(booking.status)
        || !bookingBelongsToField(booking, field)) return false;
      const bookingStart = validDate(booking.startTime);
      const bookingFinish = bookingEnd(booking);
      return occurrences.some((item) => (
        validDate(item.startTime) < bookingFinish && validDate(item.endTime) > bookingStart
      ));
    });
    if (activeBookings.length && req.body?.force !== true) {
      return res.status(409).json({
        message: 'توجد حجوزات متعارضة',
        code: 'BOOKING_CONFLICT',
        conflicts: activeBookings.map((booking) => Number(booking.id)),
      });
    }
    const block = await store().insert('maintenanceBlocks', {
      fieldId: publicNumericId(field),
      fieldName: field.name,
      startTime: start.toISOString(),
      endTime: end.toISOString(),
      reason: String(req.body?.reason || '').trim(),
      notes: String(req.body?.notes || '').trim() || null,
      recurrence,
      recurrenceEnd: recurrence === 'none' ? null : recurrenceEnd.toISOString(),
      status: 'active',
      createdBy: Number(req.user.id),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
    await audit(req, 'maintenance.created', 'maintenanceBlock', block.id, {
      fieldId: block.fieldId, conflicts: activeBookings.map((booking) => booking.id),
    });
    await createAlert({
      type: 'maintenance',
      severity: activeBookings.length ? 'warning' : 'info',
      title: 'حظر صيانة جديد',
      message: `${field.name}: ${block.reason || 'صيانة مجدولة'}`,
      actionUrl: '/maintenance/new',
      entityType: 'maintenanceBlock',
      entityId: block.id,
      data: { maintenanceBlockId: block.id, fieldId: block.fieldId, recurrence },
    });
    publish('admin:maintenance.created', block);
    emitToField(publicNumericId(field), 'maintenanceUpdated', block);
    res.status(201).json(block);
  });

  app.patch('/api/admin/maintenance-blocks/:id', auth, permit('maintenance.manage'), async (req, res) => {
    const existing = await store().findById('maintenanceBlocks', req.params.id);
    if (!existing) return res.status(404).json({ message: 'حظر الصيانة غير موجود' });
    const patch = {};
    for (const key of ['reason', 'notes']) {
      if (req.body?.[key] !== undefined) patch[key] = req.body[key];
    }
    if (req.body?.status !== undefined) {
      if (!['active', 'cancelled'].includes(req.body.status)) {
        return res.status(400).json({ message: 'حالة الصيانة غير صالحة' });
      }
      patch.status = req.body.status;
    }
    if (req.body?.startTime !== undefined) {
      const start = validDate(req.body.startTime);
      if (!start) return res.status(400).json({ message: 'وقت البدء غير صالح' });
      patch.startTime = start.toISOString();
    }
    if (req.body?.endTime !== undefined) {
      const end = validDate(req.body.endTime);
      if (!end) return res.status(400).json({ message: 'وقت الانتهاء غير صالح' });
      patch.endTime = end.toISOString();
    }
    if (req.body?.recurrence !== undefined) {
      const recurrence = normalizeRecurrence(req.body.recurrence);
      if (!recurrence) return res.status(400).json({ message: 'نمط التكرار غير صالح' });
      patch.recurrence = recurrence;
    }
    if (req.body?.recurrenceEnd !== undefined) {
      const recurrenceEnd = recurrenceEndDate(req.body.recurrenceEnd);
      if (!recurrenceEnd) return res.status(400).json({ message: 'نهاية التكرار غير صالحة' });
      patch.recurrenceEnd = recurrenceEnd.toISOString();
    }
    const candidateStart = validDate(patch.startTime || existing.startTime);
    const candidateEnd = validDate(patch.endTime || existing.endTime);
    const candidateRecurrence = normalizeRecurrence(patch.recurrence ?? existing.recurrence) || 'none';
    const candidateRecurrenceEnd = validDate(patch.recurrenceEnd ?? existing.recurrenceEnd);
    if (candidateEnd <= candidateStart) {
      return res.status(400).json({ message: 'نطاق الصيانة غير صالح' });
    }
    if (candidateRecurrence !== 'none' && (!candidateRecurrenceEnd
      || candidateRecurrenceEnd < candidateStart
      || candidateRecurrenceEnd > new Date(candidateStart.getTime() + 366 * 86400000))) {
      return res.status(400).json({ message: 'نهاية التكرار مطلوبة ويجب ألا تتجاوز سنة' });
    }
    if (candidateRecurrence === 'none') patch.recurrenceEnd = null;
    const field = await resolveField(existing.fieldId);
    const candidate = {
      ...existing,
      ...patch,
      recurrence: candidateRecurrence,
      recurrenceEnd: candidateRecurrence === 'none' ? null : candidateRecurrenceEnd.toISOString(),
    };
    const candidateOccurrences = expandMaintenanceBlock(candidate);
    const conflictingBookings = (await store().find('bookings')).filter((booking) => {
      if (!['pending', 'approved'].includes(booking.status)
        || !field || !bookingBelongsToField(booking, field)) return false;
      const bookingStart = validDate(booking.startTime);
      const bookingFinish = bookingEnd(booking);
      return candidateOccurrences.some((item) => (
        validDate(item.startTime) < bookingFinish && validDate(item.endTime) > bookingStart
      ));
    });
    if (candidate.status !== 'cancelled' && conflictingBookings.length && req.body?.force !== true) {
      return res.status(409).json({
        message: 'توجد حجوزات متعارضة',
        code: 'BOOKING_CONFLICT',
        conflicts: conflictingBookings.map((booking) => Number(booking.id)),
      });
    }
    patch.updatedAt = new Date().toISOString();
    const updated = await store().update('maintenanceBlocks', existing.id, patch);
    await audit(req, 'maintenance.updated', 'maintenanceBlock', existing.id, patch);
    publish('admin:maintenance.updated', updated);
    emitToField(existing.fieldId, 'maintenanceUpdated', updated);
    res.json(updated);
  });

  app.delete('/api/admin/maintenance-blocks/:id', auth, permit('maintenance.manage'), async (req, res) => {
    const existing = await store().findById('maintenanceBlocks', req.params.id);
    if (!existing) return res.status(404).json({ message: 'حظر الصيانة غير موجود' });
    const updated = await store().update('maintenanceBlocks', existing.id, {
      status: 'cancelled',
      cancelledAt: new Date().toISOString(),
      cancelledBy: Number(req.user.id),
      updatedAt: new Date().toISOString(),
    });
    await audit(req, 'maintenance.cancelled', 'maintenanceBlock', existing.id);
    publish('admin:maintenance.cancelled', updated);
    emitToField(existing.fieldId, 'maintenanceUpdated', updated);
    res.json(updated);
  });

  app.get('/api/admin/calendar', auth, permit('bookings.read'), async (req, res) => {
    const bookings = await hydratedBookings(req.query);
    const range = dateRange(req.query);
    let maintenance = await store().find('maintenanceBlocks');
    maintenance = maintenance.filter((block) => block.status !== 'cancelled'
      && (!req.query.fieldId || sameId(block.fieldId, req.query.fieldId)))
      .flatMap((block) => expandMaintenanceBlock(block, range.from, range.to));
    const bookingItems = bookings.map((booking) => ({
      ...booking, type: 'booking', eventType: 'booking', title: booking.fieldName,
    }));
    const maintenanceItems = maintenance.map((block) => ({
      ...block,
      id: block.occurrenceId,
      maintenanceBlockId: block.parentId,
      type: 'maintenance',
      eventType: 'maintenance',
      title: block.reason || block.fieldName,
    }));
    res.json({
      items: [...bookingItems, ...maintenanceItems]
        .sort((a, b) => new Date(a.startTime) - new Date(b.startTime)),
      bookings: bookingItems,
      maintenance: maintenanceItems,
    });
  });

  const manualBookingHandler = async (req, res) => {
    const field = await resolveField(req.body?.fieldId);
    if (!field || field.isActive === false) return res.status(404).json({ message: 'الملعب غير موجود' });
    const start = validDate(req.body?.startTime);
    const hours = Number(req.body?.hours) || 1;
    if (!start || start <= new Date() || hours <= 0 || hours > 24) {
      return res.status(400).json({ message: 'وقت أو مدة الحجز غير صالحة' });
    }
    const conflict = await bookingConflict(field, start, hours);
    if (conflict) {
      return res.status(409).json({
        message: conflict.type === 'maintenance' ? 'الملعب محظور للصيانة' : 'وقت الحجز متعارض',
        code: conflict.type === 'maintenance' ? 'MAINTENANCE_CONFLICT' : 'BOOKING_CONFLICT',
        conflictId: Number(conflict.record.id),
      });
    }
    let user = null;
    if (req.body?.userId) {
      user = await store().findById('users', req.body.userId);
      if (!user) {
        const users = await store().find('users');
        user = users.find((candidate) => String(candidate.phone || '') === String(req.body.userId));
      }
    }
    if (!user && req.body?.customerEmail) {
      const users = await store().find('users');
      user = users.find((candidate) => String(candidate.email || '').toLowerCase()
        === String(req.body.customerEmail).trim().toLowerCase());
    }
    if (!user) return res.status(400).json({ message: 'مستخدم صالح مطلوب للحجز اليدوي' });
    const requestedMethod = String(req.body?.paymentMethod || 'cash').toLowerCase();
    const paymentMethod = electronicPaymentsEnabled
      && ['online', 'card', 'wallet'].includes(requestedMethod)
      ? requestedMethod
      : 'cash';
    const booking = await store().insert('bookings', {
      fieldId: field.id,
      fieldPublicId: publicNumericId(field),
      ownerId: Number(field.ownerId) || 0,
      userId: Number(user.id),
      startTime: start.toISOString(),
      hours,
      totalPrice: req.body?.totalPrice == null
        ? (Number(field.pricePerHour) || 0) * hours
        : Math.max(0, Number(req.body.totalPrice) || 0),
      status: req.body?.status === 'pending' ? 'pending' : 'approved',
      paymentMethod,
      paymentStatus: req.body?.paymentStatus === 'paid'
        ? 'paid'
        : (paymentMethod === 'cash' ? 'pay_at_venue' : 'unpaid'),
      referenceCode: `ADM-${Date.now().toString(36).toUpperCase()}-${crypto.randomBytes(2).toString('hex').toUpperCase()}`,
      source: 'admin',
      adminNotes: String(req.body?.notes || '').trim() || null,
      createdByAdminId: Number(req.user.id),
      createdAt: new Date().toISOString(),
      walletCredited: false,
    });
    if (booking.paymentStatus === 'paid' && creditOwnerForPaidBooking) {
      await creditOwnerForPaidBooking(booking);
    }
    await audit(req, 'booking.manual.created', 'booking', booking.id, {
      fieldId: publicNumericId(field), userId: user.id,
    });
    await notify(user.id, 'تم إنشاء حجز لك', `تم إنشاء حجز إداري في ${field.name}`);
    emitBookingUpdated(user.id, booking, 'bookingApproved', 'bookingApproved');
    publish('admin:booking.created', booking);
    emitToField(publicNumericId(field), 'bookingCreated', booking);
    res.status(201).json(adminBookingDto(booking, user, field));
  };
  app.post('/api/admin/bookings/manual', auth, permit('bookings.manual'), manualBookingHandler);
  app.post('/api/admin/bookings', auth, permit('bookings.manual'), manualBookingHandler);

  const editBookingHandler = async (req, res) => {
    const booking = await store().findById('bookings', req.params.id);
    if (!booking) return res.status(404).json({ message: 'الحجز غير موجود' });
    const fields = await store().find('fields');
    const oldField = fields.find((field) => bookingBelongsToField(booking, field));
    const field = req.body?.fieldId ? await resolveField(req.body.fieldId) : oldField;
    if (!field) return res.status(404).json({ message: 'الملعب غير موجود' });
    const start = validDate(req.body?.startTime || booking.startTime);
    const hours = Number(req.body?.hours ?? booking.hours) || 1;
    if (!start || hours <= 0 || hours > 24) return res.status(400).json({ message: 'وقت أو مدة غير صالحة' });
    const conflict = await bookingConflict(field, start, hours, booking.id);
    if (conflict) {
      return res.status(409).json({
        message: conflict.type === 'maintenance' ? 'الملعب محظور للصيانة' : 'وقت الحجز متعارض',
        code: conflict.type === 'maintenance' ? 'MAINTENANCE_CONFLICT' : 'BOOKING_CONFLICT',
        conflictId: Number(conflict.record.id),
      });
    }
    const patch = {
      fieldId: field.id,
      fieldPublicId: publicNumericId(field),
      ownerId: Number(field.ownerId) || 0,
      startTime: start.toISOString(),
      hours,
      updatedAt: new Date().toISOString(),
      updatedByAdminId: Number(req.user.id),
    };
    for (const key of ['status', 'paymentStatus', 'paymentMethod', 'adminNotes']) {
      if (req.body?.[key] !== undefined) patch[key] = req.body[key];
    }
    if (req.body?.totalPrice !== undefined) patch.totalPrice = Math.max(0, Number(req.body.totalPrice) || 0);
    const updated = await store().update('bookings', booking.id, patch);
    if (updated.paymentStatus === 'paid' && creditOwnerForPaidBooking) {
      await creditOwnerForPaidBooking(updated);
    }
    await audit(req, 'booking.updated', 'booking', booking.id, patch);
    await notify(booking.userId, 'تم تعديل الحجز', `تم تعديل حجزك ${booking.referenceCode || booking.id}`);
    emitBookingUpdated(booking.userId, updated, 'bookingUpdated', 'bookingUpdated');
    publish('admin:booking.updated', updated);
    if (oldField) emitToField(publicNumericId(oldField), 'bookingUpdated', updated);
    if (!oldField || !sameId(oldField.id, field.id)) emitToField(publicNumericId(field), 'bookingUpdated', updated);
    const user = await store().findById('users', booking.userId);
    res.json(adminBookingDto(updated, user, field));
  };
  app.patch('/api/admin/bookings/:id', auth, permit('bookings.manage'), editBookingHandler);
  app.post('/api/admin/bookings/:id/reschedule', auth, permit('bookings.manage'), async (req, res) => {
    req.body = {
      ...req.body,
      adminNotes: [
        req.body?.reason ? `Rescheduled: ${req.body.reason}` : '',
      ].filter(Boolean).join('\n'),
    };
    return editBookingHandler(req, res);
  });

  app.get('/api/admin/bookings/:id', auth, permit('bookings.read'), async (req, res) => {
    const booking = await store().findById('bookings', req.params.id);
    if (!booking) return res.status(404).json({ message: 'الحجز غير موجود' });
    const [users, fields, logs] = await Promise.all([
      store().find('users'),
      store().find('fields'),
      store().find('auditLogs'),
    ]);
    const user = users.find((item) => sameId(item.id, booking.userId));
    const field = fields.find((item) => bookingBelongsToField(booking, item));
    const dto = adminBookingDto(booking, user, field);
    dto.history = logs.filter((log) => log.resourceType === 'booking'
      && sameId(log.resourceId, booking.id))
      .sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt))
      .map((log) => ({
        id: log.id,
        action: log.action,
        label: log.action,
        actorId: log.actorId,
        actorName: log.actorName,
        createdAt: log.createdAt,
      }));
    return res.json(dto);
  });

  app.post('/api/admin/bookings/bulk', auth, permit('bookings.manage'), async (req, res) => {
    const ids = [...new Set((req.body?.bookingIds || []).map(Number))]
      .filter((id) => Number.isFinite(id) && id > 0);
    const action = String(req.body?.action || '');
    if (!ids.length || !['approve', 'reject', 'cancel', 'complete', 'mark_paid'].includes(action)) {
      return res.status(400).json({ message: 'إجراء جماعي غير صالح' });
    }
    const statusByAction = {
      approve: 'approved', reject: 'rejected', cancel: 'cancelled', complete: 'completed',
    };
    const results = [];
    for (const id of ids.slice(0, 200)) {
      const booking = await store().findById('bookings', id);
      if (!booking) {
        results.push({ id, ok: false, message: 'الحجز غير موجود' });
        continue;
      }
      const patch = action === 'mark_paid'
        ? { paymentStatus: 'paid', paidAt: new Date().toISOString(), paidByAdminId: Number(req.user.id) }
        : { status: statusByAction[action], updatedAt: new Date().toISOString() };
      const updated = await store().update('bookings', id, patch);
      if (updated.paymentStatus === 'paid' && creditOwnerForPaidBooking) {
        await creditOwnerForPaidBooking(updated);
      }
      emitBookingUpdated(booking.userId, updated, 'bookingUpdated', 'bookingUpdated');
      results.push({ id, ok: true, status: updated.status, paymentStatus: updated.paymentStatus });
    }
    await audit(req, `booking.bulk.${action}`, 'booking', null, {
      bookingIds: ids.slice(0, 200), succeeded: results.filter((item) => item.ok).length,
    });
    publish('admin:bookings.bulk-updated', { action, results });
    res.json({
      action,
      total: results.length,
      succeeded: results.filter((item) => item.ok).length,
      failed: results.filter((item) => !item.ok).length,
      results,
    });
  });

  async function financialReport(query = {}) {
    const rows = await hydratedBookings(query);
    const expectedRows = rows.filter((row) => ['approved', 'completed'].includes(row.status));
    const realizedRows = rows.filter((row) => row.paymentStatus === 'paid');
    const expectedRevenueIqd = expectedRows.reduce((sum, row) => sum + row.totalPrice, 0);
    const realizedRevenueIqd = realizedRows.reduce((sum, row) => sum + row.totalPrice, 0);
    const groups = new Map();
    for (const row of rows) {
      const key = String(row.ownerId || 0);
      const group = groups.get(key) || {
        ownerId: row.ownerId, expectedRevenueIqd: 0, realizedRevenueIqd: 0,
        expectedCommissionIqd: 0, realizedCommissionIqd: 0, bookingCount: 0,
      };
      group.bookingCount += 1;
      if (['approved', 'completed'].includes(row.status)) group.expectedRevenueIqd += row.totalPrice;
      if (row.paymentStatus === 'paid') group.realizedRevenueIqd += row.totalPrice;
      group.expectedCommissionIqd = Math.round(group.expectedRevenueIqd * commissionRate);
      group.realizedCommissionIqd = Math.round(group.realizedRevenueIqd * commissionRate);
      groups.set(key, group);
    }
    const reportRange = dateRange(query);
    const settlements = await store().find('settlements');
    const settledIqd = settlements.filter((settlement) => (
      settlement.status === 'paid'
      && (!query.ownerId || sameId(settlement.ownerId, query.ownerId))
      && (!(reportRange.from || reportRange.to) || inRange(settlement.paidAt || settlement.createdAt, reportRange))
    ))
      .reduce((sum, settlement) => sum + (Number(settlement.amountIqd) || 0), 0);
    return {
      range: {
        from: reportRange.from?.toISOString() || null,
        to: reportRange.to?.toISOString() || null,
      },
      currency: 'IQD',
      expectedRevenueIqd,
      realizedRevenueIqd,
      outstandingRevenueIqd: Math.max(0, expectedRevenueIqd - realizedRevenueIqd),
      expectedCommissionIqd: Math.round(expectedRevenueIqd * commissionRate),
      realizedCommissionIqd: Math.round(realizedRevenueIqd * commissionRate),
      settledIqd,
      bookingCount: rows.length,
      paidBookingCount: realizedRows.length,
      byOwner: [...groups.values()],
      bookings: rows,
    };
  }

  app.get('/api/admin/analytics', auth, permit('analytics.read'), async (req, res) => {
    const report = await financialReport(req.query);
    const rows = report.bookings;
    const byDay = new Map();
    for (const row of rows) {
      const day = validDate(row.startTime)?.toISOString().slice(0, 10);
      if (!day) continue;
      const bucket = byDay.get(day) || {
        date: day, bookings: 0, expectedRevenueIqd: 0, realizedRevenueIqd: 0,
      };
      bucket.bookings += 1;
      if (['approved', 'completed'].includes(row.status)) bucket.expectedRevenueIqd += row.totalPrice;
      if (row.paymentStatus === 'paid') bucket.realizedRevenueIqd += row.totalPrice;
      byDay.set(day, bucket);
    }
    res.json({
      summary: { ...report, bookings: undefined, byOwner: undefined },
      series: [...byDay.values()].sort((a, b) => a.date.localeCompare(b.date)),
      byOwner: report.byOwner,
      statusBreakdown: Object.entries(rows.reduce((acc, row) => {
        acc[row.status] = (acc[row.status] || 0) + 1;
        return acc;
      }, {})).map(([status, count]) => ({ status, count })),
    });
  });

  app.get('/api/admin/analytics/dashboard', auth, permit('analytics.read'), async (req, res) => {
    const report = await financialReport(req.query);
    const active = report.bookings.filter((booking) => !['cancelled', 'rejected'].includes(booking.status));
    const hourCounts = {};
    const fieldCounts = {};
    for (const booking of active) {
      const hour = validDate(booking.startTime)?.getHours();
      if (hour != null) hourCounts[hour] = (hourCounts[hour] || 0) + 1;
      fieldCounts[booking.fieldName || '—'] = (fieldCounts[booking.fieldName || '—'] || 0) + 1;
    }
    const peak = Object.entries(hourCounts).sort((a, b) => b[1] - a[1])[0]?.[0];
    const topField = Object.entries(fieldCounts).sort((a, b) => b[1] - a[1])[0] || null;
    const range = dateRange(req.query, 30);
    const days = Math.max(1, Math.ceil(((range.to || new Date()) - range.from) / 86400000) + 1);
    const fields = await store().find('fields');
    const availableHours = Math.max(1, fields.filter((field) => field.isActive !== false).length * days * 13);
    const bookedHours = active.reduce((sum, booking) => sum + booking.hours, 0);
    const occupancyRate = Math.round(bookedHours / availableHours * 1000) / 10;
    const previousTo = new Date(range.from.getTime() - 1);
    const previousFrom = new Date(previousTo.getTime() - (days * 86400000) + 1);
    const previous = await financialReport({
      ...req.query,
      from: previousFrom.toISOString(),
      to: previousTo.toISOString(),
    });
    const previousActive = previous.bookings
      .filter((booking) => !['cancelled', 'rejected'].includes(booking.status));
    const previousOccupancy = Math.round(
      previousActive.reduce((sum, booking) => sum + booking.hours, 0) / availableHours * 1000,
    ) / 10;
    const percentageChange = (current, old) => (
      old ? Math.round(((current - old) / Math.abs(old)) * 1000) / 10 : null
    );
    const trend = new Map();
    for (const booking of active) {
      const date = validDate(booking.startTime)?.toISOString().slice(0, 10);
      if (!date) continue;
      const item = trend.get(date) || { date, expected: 0, realized: 0 };
      if (['approved', 'completed'].includes(booking.status)) item.expected += booking.totalPrice;
      if (booking.paymentStatus === 'paid') item.realized += booking.totalPrice;
      trend.set(date, item);
    }
    res.json({
      expectedRevenue: report.expectedRevenueIqd,
      realizedRevenue: report.realizedRevenueIqd,
      occupancyRate,
      peakHour: peak == null ? null : `${String(peak).padStart(2, '0')}:00`,
      topField: topField?.[0] || null,
      topMetric: topField ? { label: topField[0], bookingCount: topField[1] } : null,
      comparison: {
        expected: percentageChange(report.expectedRevenueIqd, previous.expectedRevenueIqd),
        realized: percentageChange(report.realizedRevenueIqd, previous.realizedRevenueIqd),
        occupancy: percentageChange(occupancyRate, previousOccupancy),
      },
      trend: [...trend.values()].sort((a, b) => a.date.localeCompare(b.date)),
    });
  });

  app.get('/api/admin/reports/financials', auth, permit('finance.read'), async (req, res) => {
    const report = await financialReport(req.query);
    if (String(req.query.format || '').toLowerCase() === 'csv') {
      const csv = toCsv(report.bookings, [
        ['id', 'bookingId'], ['referenceCode', 'referenceCode'], ['fieldName', 'fieldName'],
        ['ownerId', 'ownerId'], ['userName', 'userName'], ['startTime', 'startTime'],
        ['status', 'status'], ['paymentStatus', 'paymentStatus'], ['totalPrice', 'totalPriceIqd'],
      ]);
      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', 'attachment; filename="financial-report.csv"');
      return res.send(csv);
    }
    return res.json({
      ...report,
      rows: report.bookings,
      exportFormats: {
        csv: { generation: 'server', endpoint: '/api/admin/reports/exports' },
        xlsx: { generation: 'client', source: 'rows' },
        pdf: { generation: 'client', source: 'rows' },
      },
    });
  });

  async function formattedReport(query = {}) {
    const type = String(query.type || 'revenue');
    const report = await financialReport(query);
    if (type === 'bookings') {
      return {
        type,
        summary: {
          totalBookings: report.bookingCount,
          paidBookings: report.paidBookingCount,
          expectedRevenue: report.expectedRevenueIqd,
          realizedRevenue: report.realizedRevenueIqd,
        },
        columns: [
          { key: 'id', label: 'ID' },
          { key: 'referenceCode', label: 'Reference' },
          { key: 'fieldName', label: 'Field' },
          { key: 'userName', label: 'Customer' },
          { key: 'startTime', label: 'Start' },
          { key: 'status', label: 'Status' },
          { key: 'paymentStatus', label: 'Payment' },
          { key: 'totalPrice', label: 'Amount IQD' },
        ],
        items: report.bookings,
      };
    }
    if (type === 'occupancy') {
      const fields = await store().find('fields');
      const totalHours = report.bookings
        .filter((booking) => !['cancelled', 'rejected'].includes(booking.status))
        .reduce((sum, booking) => sum + booking.hours, 0);
      const range = dateRange(query, 30);
      const dayCount = Math.max(1, Math.ceil(((range.to || new Date()) - range.from) / 86400000) + 1);
      const availableHours = Math.max(1, fields.filter((field) => field.isActive !== false).length * dayCount * 13);
      const byField = new Map();
      for (const booking of report.bookings) {
        const bucket = byField.get(booking.fieldId) || {
          id: booking.fieldId, fieldName: booking.fieldName, bookedHours: 0, bookings: 0,
        };
        if (!['cancelled', 'rejected'].includes(booking.status)) bucket.bookedHours += booking.hours;
        bucket.bookings += 1;
        byField.set(booking.fieldId, bucket);
      }
      const items = [...byField.values()].map((item) => ({
        ...item,
        occupancyRate: Math.round(item.bookedHours / Math.max(1, dayCount * 13) * 1000) / 10,
      }));
      return {
        type,
        summary: {
          occupancyRate: Math.round(totalHours / availableHours * 1000) / 10,
          bookedHours: totalHours,
          availableHours,
          activeFields: fields.filter((field) => field.isActive !== false).length,
        },
        columns: [
          { key: 'fieldName', label: 'Field' },
          { key: 'bookings', label: 'Bookings' },
          { key: 'bookedHours', label: 'Booked hours' },
          { key: 'occupancyRate', label: 'Occupancy %' },
        ],
        items,
      };
    }
    const users = await store().find('users');
    const items = report.byOwner.map((item) => ({
      ...item,
      id: item.ownerId,
      ownerName: users.find((user) => sameId(user.id, item.ownerId))?.name || '',
    }));
    return {
      type: 'revenue',
      summary: {
        expectedRevenue: report.expectedRevenueIqd,
        realizedRevenue: report.realizedRevenueIqd,
        outstandingRevenue: report.outstandingRevenueIqd,
        realizedCommission: report.realizedCommissionIqd,
      },
      columns: [
        { key: 'ownerName', label: 'Owner' },
        { key: 'bookingCount', label: 'Bookings' },
        { key: 'expectedRevenueIqd', label: 'Expected IQD' },
        { key: 'realizedRevenueIqd', label: 'Realized IQD' },
        { key: 'realizedCommissionIqd', label: 'Commission IQD' },
      ],
      items,
    };
  }

  app.get('/api/admin/reports', auth, permit('finance.read'), async (req, res) => {
    const report = await formattedReport(req.query);
    res.json({
      ...report,
      rows: report.items,
      exportFormats: {
        csv: { generation: 'server', endpoint: '/api/admin/reports/exports' },
        xlsx: { generation: 'client', source: 'rows' },
        pdf: { generation: 'client', source: 'rows' },
      },
    });
  });

  app.post('/api/admin/reports/exports', auth, permit('finance.read'), async (req, res) => {
    const report = await formattedReport(req.body || {});
    const format = String(req.body?.format || 'csv').toLowerCase();
    if (!['csv', 'xlsx', 'pdf'].includes(format)) {
      return res.status(400).json({ message: 'صيغة التصدير غير مدعومة' });
    }
    if (format !== 'csv') {
      await audit(req, 'report.export.client-data', 'report', report.type, {
        format, rows: report.items.length,
      });
      return res.json({
        format,
        generation: 'client',
        contentType: format === 'xlsx'
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'application/pdf',
        summary: report.summary,
        columns: report.columns,
        rows: report.items,
        rowCount: report.items.length,
      });
    }
    const columns = report.columns.map((column) => [column.key, column.label]);
    const csv = toCsv(report.items, columns);
    const token = crypto.randomBytes(24).toString('base64url');
    reportExports.set(token, {
      csv,
      expiresAt: Date.now() + 5 * 60 * 1000,
      filename: `${report.type}-report.csv`,
    });
    await audit(req, 'report.export.created', 'report', report.type, {
      format: 'csv', rows: report.items.length,
    });
    res.status(201).json({
      format: 'csv',
      generation: 'server',
      rowCount: report.items.length,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
      downloadUrl: `/api/admin/reports/exports/${token}`,
    });
  });

  app.get('/api/admin/reports/exports/:token', (req, res) => {
    const item = reportExports.get(req.params.token);
    reportExports.delete(req.params.token);
    if (!item || item.expiresAt < Date.now()) {
      return res.status(404).json({ message: 'رابط التصدير منتهي أو غير صالح' });
    }
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${item.filename}"`);
    return res.send(item.csv);
  });

  app.get('/api/admin/settlements', auth, permit('settlements.read'), async (req, res) => {
    const range = dateRange(req.query);
    let rows = await store().find('settlements');
    rows = rows.filter((row) => {
      if (req.query.ownerId && !sameId(row.ownerId, req.query.ownerId)) return false;
      if (req.query.status && row.status !== req.query.status) return false;
      if ((range.from || range.to) && !inRange(row.createdAt, range)) return false;
      return true;
    }).sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .map((row) => ({
        ...row,
        grossAmount: Number(row.grossAmount ?? row.amountIqd) || 0,
        platformFee: Number(row.platformFee) || 0,
        netAmount: Number(row.netAmount ?? row.amountIqd) || 0,
      }));
    res.json(paginate(rows, req.query));
  });

  app.post('/api/admin/settlements', auth, permit('settlements.manage'), async (req, res) => {
    const owner = await store().findById('users', req.body?.ownerId);
    const grossAmount = Math.round(Number(req.body?.grossAmount ?? req.body?.amountIqd));
    const platformFee = Math.max(0, Math.round(Number(
      req.body?.platformFee ?? (grossAmount * commissionRate),
    ) || 0));
    const netAmount = Math.round(Number(req.body?.netAmount ?? (grossAmount - platformFee)));
    const amountIqd = netAmount;
    if (!owner || owner.role !== 'owner') return res.status(404).json({ message: 'المالك غير موجود' });
    if (!Number.isFinite(amountIqd) || amountIqd <= 0) return res.status(400).json({ message: 'المبلغ غير صالح' });
    const periodStart = validDate(req.body?.periodStart);
    const periodEnd = validDate(req.body?.periodEnd);
    if (periodStart && periodEnd && periodEnd < periodStart) {
      return res.status(400).json({ message: 'فترة التسوية غير صالحة' });
    }
    const idempotencyKey = String(req.body?.idempotencyKey || '').trim();
    if (idempotencyKey) {
      const duplicate = (await store().find('settlements'))
        .find((item) => item.idempotencyKey === idempotencyKey);
      if (duplicate) return res.status(200).json(duplicate);
    }
    const settlement = await store().insert('settlements', {
      ownerId: Number(owner.id),
      ownerName: owner.name,
      amountIqd,
      grossAmount,
      platformFee,
      netAmount,
      status: 'pending',
      periodStart: periodStart?.toISOString() || null,
      periodEnd: periodEnd?.toISOString() || null,
      method: String(req.body?.method || 'manual'),
      reference: String(req.body?.reference || '').trim() || null,
      evidenceUrl: String(req.body?.evidenceUrl || '').trim() || null,
      evidenceNote: String(req.body?.evidenceNote || '').trim() || null,
      notes: String(req.body?.notes || '').trim() || null,
      ...(idempotencyKey ? { idempotencyKey } : {}),
      createdBy: Number(req.user.id),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      approvedAt: null,
      approvedBy: null,
      paidAt: null,
      paidBy: null,
      voidedAt: null,
      voidedBy: null,
    });
    await audit(req, 'settlement.created', 'settlement', settlement.id, {
      ownerId: owner.id, amountIqd, status: settlement.status,
    });
    publish('admin:settlement.created', settlement);
    res.status(201).json(settlement);
  });

  app.get('/api/admin/settlements/:id', auth, permit('settlements.read'), async (req, res) => {
    const settlement = await store().findById('settlements', req.params.id);
    if (!settlement) return res.status(404).json({ message: 'التسوية غير موجودة' });
    res.json({
      ...settlement,
      grossAmount: Number(settlement.grossAmount ?? settlement.amountIqd) || 0,
      platformFee: Number(settlement.platformFee) || 0,
      netAmount: Number(settlement.netAmount ?? settlement.amountIqd) || 0,
    });
  });

  app.patch('/api/admin/settlements/:id', auth, permit('settlements.manage'), async (req, res) => {
    const settlement = await store().findById('settlements', req.params.id);
    if (!settlement) return res.status(404).json({ message: 'التسوية غير موجودة' });
    const currentStatus = ['pending', 'approved', 'paid', 'void'].includes(settlement.status)
      ? settlement.status
      : 'pending';
    const requestedStatus = req.body?.status == null ? currentStatus : String(req.body.status);
    const transitions = {
      pending: ['pending', 'approved', 'void'],
      approved: ['approved', 'paid', 'void'],
      paid: ['paid'],
      void: ['void'],
    };
    if (!transitions[currentStatus].includes(requestedStatus)) {
      return res.status(409).json({
        message: `انتقال حالة التسوية غير مسموح: ${currentStatus} → ${requestedStatus}`,
        code: 'INVALID_SETTLEMENT_TRANSITION',
      });
    }
    const patch = {};
    for (const key of ['method', 'reference', 'notes', 'evidenceUrl', 'evidenceNote']) {
      if (req.body?.[key] !== undefined) patch[key] = req.body[key];
    }
    patch.status = requestedStatus;
    if (requestedStatus === 'approved' && currentStatus === 'pending') {
      patch.approvedAt = new Date().toISOString();
      patch.approvedBy = Number(req.user.id);
      patch.approvalNote = String(req.body?.approvalNote || '').trim() || null;
    }
    if (requestedStatus === 'paid' && currentStatus === 'approved') {
      patch.paidAt = validDate(req.body?.paidAt)?.toISOString() || new Date().toISOString();
      patch.paidBy = Number(req.user.id);
      patch.paymentEvidence = req.body?.paymentEvidence || null;
    }
    if (requestedStatus === 'void' && currentStatus !== 'void') {
      const voidReason = String(req.body?.voidReason || '').trim();
      if (!voidReason) return res.status(400).json({ message: 'سبب الإلغاء مطلوب' });
      patch.voidReason = voidReason;
      patch.voidedAt = new Date().toISOString();
      patch.voidedBy = Number(req.user.id);
    }
    patch.updatedAt = new Date().toISOString();
    const updated = await store().update('settlements', settlement.id, patch);
    await audit(req, `settlement.${requestedStatus}`, 'settlement', settlement.id, {
      from: currentStatus, to: requestedStatus, ...patch,
    });
    publish('admin:settlement.updated', updated);
    res.json(updated);
  });

  app.get('/api/admin/alerts', auth, permit('alerts.read'), async (req, res) => {
    let rows = await store().find('adminAlerts');
    const now = new Date();
    for (const row of rows) {
      if (row.status === 'snoozed' && validDate(row.snoozeUntil) <= now) {
        row.status = 'open';
        row.snoozeUntil = null;
        await store().update('adminAlerts', row.id, {
          status: 'open', snoozeUntil: null, updatedAt: now.toISOString(),
        });
      }
    }
    rows = rows.filter((row) => {
      if (req.query.status && row.status !== req.query.status) return false;
      if (req.query.severity && row.severity !== req.query.severity) return false;
      if (req.query.type && row.type !== req.query.type) return false;
      if (req.query.entityType && row.entityType !== req.query.entityType) return false;
      if (req.query.entityId && !sameId(row.entityId, req.query.entityId)) return false;
      if (req.query.assignedTo === 'me' && !sameId(row.assignedTo, req.user.id)) return false;
      if (req.query.assignedTo === 'unassigned' && row.assignedTo != null) return false;
      if (req.query.assignedTo && !['me', 'unassigned'].includes(req.query.assignedTo)
        && !sameId(row.assignedTo, req.query.assignedTo)) return false;
      if (String(req.query.includeSnoozed || '').toLowerCase() !== 'true'
        && !req.query.status && row.status === 'snoozed') return false;
      if (String(req.query.unread || '').toLowerCase() === 'true'
        && (row.readBy || []).some((id) => sameId(id, req.user.id))) return false;
      return true;
    }).sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .map((row) => ({
        ...row,
        readAt: (row.readBy || []).some((id) => sameId(id, req.user.id))
          ? (row.updatedAt || row.createdAt)
          : null,
      }));
    const payload = paginate(rows, req.query);
    payload.unreadCount = rows.filter((row) => !(row.readBy || []).some((id) => sameId(id, req.user.id))).length;
    res.json(payload);
  });

  app.post('/api/admin/alerts', auth, permit('alerts.manage'), async (req, res) => {
    if (req.body?.assignedTo != null) {
      const assignee = await store().findById('users', req.body.assignedTo);
      if (!assignee || assignee.role !== 'admin' || assignee.adminStatus === 'suspended') {
        return res.status(400).json({ message: 'المسؤول المعيّن غير صالح' });
      }
    }
    const alert = await createAlert({
      type: req.body?.type,
      severity: req.body?.severity,
      title: req.body?.title,
      message: req.body?.message,
      data: req.body?.data,
      dedupeKey: req.body?.dedupeKey,
      actionUrl: req.body?.actionUrl,
      entityType: req.body?.entityType,
      entityId: req.body?.entityId,
      assignedTo: req.body?.assignedTo,
      snoozeUntil: req.body?.snoozeUntil,
    });
    await audit(req, 'alert.created', 'adminAlert', alert.id);
    res.status(201).json(alert);
  });

  app.patch('/api/admin/alerts/read-all', auth, permit('alerts.read'), async (req, res) => {
    const alerts = await store().find('adminAlerts');
    let updatedCount = 0;
    for (const alert of alerts) {
      if ((alert.readBy || []).some((id) => sameId(id, req.user.id))) continue;
      await store().update('adminAlerts', alert.id, {
        readBy: [...new Set([...(alert.readBy || []), Number(req.user.id)])],
        updatedAt: new Date().toISOString(),
      });
      updatedCount += 1;
    }
    res.json({ ok: true, updatedCount });
  });

  app.patch('/api/admin/alerts/:id', auth, permit('alerts.read'), async (req, res) => {
    const alert = await store().findById('adminAlerts', req.params.id);
    if (!alert) return res.status(404).json({ message: 'التنبيه غير موجود' });
    const readBy = [...new Set([...(alert.readBy || []), Number(req.user.id)])];
    const patch = { readBy, updatedAt: new Date().toISOString() };
    const workflowKeys = ['status', 'assignedTo', 'snoozeUntil', 'actionUrl', 'entityType', 'entityId'];
    if (workflowKeys.some((key) => req.body?.[key] !== undefined)) {
      if (!hasPermission(req.admin, 'alerts.manage')) {
        return res.status(403).json({ message: 'لا تملك صلاحية إدارة التنبيه' });
      }
    }
    if (req.body?.assignedTo !== undefined) {
      if (req.body.assignedTo == null || req.body.assignedTo === '') {
        patch.assignedTo = null;
        patch.assignedAt = null;
      } else {
        const assignee = await store().findById('users', req.body.assignedTo);
        if (!assignee || assignee.role !== 'admin' || assignee.adminStatus === 'suspended') {
          return res.status(400).json({ message: 'المسؤول المعيّن غير صالح' });
        }
        patch.assignedTo = Number(assignee.id);
        patch.assignedAt = new Date().toISOString();
        patch.assignedBy = Number(req.user.id);
      }
    }
    if (req.body?.actionUrl !== undefined) {
      if (req.body.actionUrl && !String(req.body.actionUrl).startsWith('/')) {
        return res.status(400).json({ message: 'رابط الإجراء يجب أن يكون مساراً داخلياً' });
      }
      patch.actionUrl = req.body.actionUrl ? String(req.body.actionUrl).slice(0, 500) : null;
    }
    for (const key of ['entityType', 'entityId']) {
      if (req.body?.[key] !== undefined) patch[key] = req.body[key] == null ? null : String(req.body[key]);
    }
    if (req.body?.snoozeUntil !== undefined) {
      const snoozeUntil = validDate(req.body.snoozeUntil);
      if (req.body.snoozeUntil && (!snoozeUntil || snoozeUntil <= new Date())) {
        return res.status(400).json({ message: 'وقت التأجيل يجب أن يكون في المستقبل' });
      }
      patch.snoozeUntil = snoozeUntil?.toISOString() || null;
      if (snoozeUntil) patch.status = 'snoozed';
    }
    if (req.body?.status !== undefined) {
      const status = String(req.body.status);
      if (!['open', 'snoozed', 'resolved', 'dismissed'].includes(status)) {
        return res.status(400).json({ message: 'حالة التنبيه غير صالحة' });
      }
      patch.status = status;
      if (status === 'snoozed' && !validDate(patch.snoozeUntil || alert.snoozeUntil)) {
        return res.status(400).json({ message: 'وقت التأجيل مطلوب' });
      }
      if (status === 'resolved') {
        patch.resolvedAt = new Date().toISOString();
        patch.resolvedBy = Number(req.user.id);
      }
      if (status === 'dismissed') {
        patch.dismissedAt = new Date().toISOString();
        patch.dismissedBy = Number(req.user.id);
      }
      if (status === 'open') patch.snoozeUntil = null;
    }
    const updated = await store().update('adminAlerts', alert.id, patch);
    if (workflowKeys.some((key) => req.body?.[key] !== undefined)) {
      await audit(req, `alert.${updated.status || 'updated'}`, 'adminAlert', alert.id, patch);
    }
    publish('admin:alert.updated', updated);
    res.json(updated);
  });

  app.patch('/api/admin/alerts/:id/read', auth, permit('alerts.read'), async (req, res) => {
    const alert = await store().findById('adminAlerts', req.params.id);
    if (!alert) return res.status(404).json({ message: 'التنبيه غير موجود' });
    const readAt = new Date().toISOString();
    const updated = await store().update('adminAlerts', alert.id, {
      readBy: [...new Set([...(alert.readBy || []), Number(req.user.id)])],
      updatedAt: readAt,
    });
    publish('admin:alert.updated', updated);
    res.json({ ...updated, readAt });
  });

  function defaultRoleRows() {
    return Object.entries(DEFAULT_ADMIN_ROLES).map(([id, permissions]) => ({
      id,
      name: id.replaceAll('_', ' '),
      permissions,
      isDefault: true,
    }));
  }

  app.get('/api/admin/roles', auth, permit('admins.manage'), async (_req, res) => {
    const custom = await store().find('adminRoles');
    res.json({
      items: [
        ...defaultRoleRows(),
        ...custom.filter((role) => role.status !== 'deleted').map((role) => ({
          ...role, isDefault: false,
        })),
      ],
      availablePermissions: ADMIN_PERMISSIONS,
    });
  });

  app.post('/api/admin/roles', auth, permit('admins.manage'), async (req, res) => {
    const name = String(req.body?.name || '').trim();
    if (!name) return res.status(400).json({ message: 'اسم الدور مطلوب' });
    const permissions = [...new Set(
      Array.isArray(req.body?.permissions) ? req.body.permissions : [],
    )].filter((permission) => ADMIN_PERMISSIONS.includes(permission));
    const role = await store().insert('adminRoles', {
      name,
      description: String(req.body?.description || '').trim() || null,
      permissions,
      status: 'active',
      createdBy: Number(req.user.id),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
    await audit(req, 'adminRole.created', 'adminRole', role.id, { permissions });
    res.status(201).json(role);
  });

  app.put('/api/admin/roles/:id', auth, permit('admins.manage'), async (req, res) => {
    if (DEFAULT_ADMIN_ROLES[req.params.id]) {
      return res.status(409).json({ message: 'لا يمكن تعديل الدور الافتراضي؛ أنشئ دوراً مخصصاً' });
    }
    const role = await store().findById('adminRoles', req.params.id);
    if (!role) return res.status(404).json({ message: 'الدور غير موجود' });
    const patch = { updatedAt: new Date().toISOString(), updatedBy: Number(req.user.id) };
    if (req.body?.name !== undefined) patch.name = String(req.body.name).trim();
    if (req.body?.description !== undefined) patch.description = String(req.body.description).trim();
    if (Array.isArray(req.body?.permissions)) {
      patch.permissions = [...new Set(req.body.permissions)]
        .filter((permission) => ADMIN_PERMISSIONS.includes(permission));
    }
    const updated = await store().update('adminRoles', role.id, patch);
    if (patch.permissions) {
      const users = await store().find('users');
      for (const user of users) {
        if (user.role === 'admin' && sameId(user.customRoleId, role.id)) {
          await store().update('users', user.id, {
            customPermissions: patch.permissions,
            permissionsUpdatedAt: new Date().toISOString(),
          });
          publish('admin:permissions.updated', { adminId: Number(user.id) });
        }
      }
    }
    await audit(req, 'adminRole.updated', 'adminRole', role.id, patch);
    res.json(updated);
  });

  app.get('/api/admin/staff', auth, permit('admins.manage'), async (req, res) => {
    const q = String(req.query.q || '').toLowerCase();
    const [users, invitations] = await Promise.all([
      store().find('users'),
      store().find('adminInvitations'),
    ]);
    let rows = [
      ...users.filter((user) => user.role === 'admin').map((user) => ({
        id: Number(user.id),
        name: user.name,
        email: user.email,
        role: user.adminRole || 'admin',
        roleName: user.adminRole || 'admin',
        permissions: effectivePermissions(user),
        status: user.adminStatus || 'active',
        type: 'staff',
      })),
      ...invitations.filter((invite) => invite.status === 'pending').map((invite) => ({
        id: `invite-${invite.id}`,
        invitationId: invite.id,
        name: invite.name,
        email: invite.email,
        role: invite.roleName || invite.roleId,
        roleName: invite.roleName || invite.roleId,
        permissions: invite.permissions || [],
        status: 'invited',
        type: 'invitation',
        expiresAt: invite.expiresAt,
      })),
    ];
    if (q) rows = rows.filter((row) => `${row.name} ${row.email} ${row.roleName}`.toLowerCase().includes(q));
    res.json(paginate(rows, req.query));
  });

  app.post('/api/admin/staff/invitations', auth, permit('admins.manage'), async (req, res) => {
    const name = String(req.body?.name || '').trim();
    const email = String(req.body?.email || '').trim().toLowerCase();
    const roleId = String(req.body?.roleId || '').trim();
    if (!name || !email || !roleId) return res.status(400).json({ message: 'الاسم والبريد والدور مطلوبة' });
    const users = await store().find('users');
    if (users.some((user) => String(user.email || '').toLowerCase() === email && user.role === 'admin')) {
      return res.status(409).json({ message: 'هذا البريد أدمن مسبقاً' });
    }
    const customRole = DEFAULT_ADMIN_ROLES[roleId]
      ? null
      : await store().findById('adminRoles', roleId);
    if (!DEFAULT_ADMIN_ROLES[roleId] && !customRole) {
      return res.status(400).json({ message: 'الدور غير موجود' });
    }
    const permissions = DEFAULT_ADMIN_ROLES[roleId] || customRole.permissions || [];
    const invitation = await store().insert('adminInvitations', {
      name,
      email,
      roleId,
      roleName: customRole?.name || roleId,
      permissions,
      status: 'pending',
      invitedBy: Number(req.user.id),
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 7 * 86400000).toISOString(),
    });
    await audit(req, 'adminInvitation.created', 'adminInvitation', invitation.id, {
      email, roleId,
    });
    await createAlert({
      type: 'security',
      severity: 'info',
      title: 'دعوة إدارية جديدة',
      message: `تم إنشاء دعوة إدارية لـ ${email}`,
      data: { invitationId: invitation.id },
    });
    res.status(201).json({
      id: invitation.id,
      name: invitation.name,
      email: invitation.email,
      roleId: invitation.roleId,
      status: invitation.status,
      expiresAt: invitation.expiresAt,
      deliveryStatus: 'not_configured',
    });
  });

  app.patch('/api/admin/staff/:id', auth, permit('admins.manage'), async (req, res) => {
    const user = await store().findById('users', req.params.id);
    if (!user || user.role !== 'admin') return res.status(404).json({ message: 'عضو الفريق غير موجود' });
    const patch = { updatedAt: new Date().toISOString(), updatedBy: Number(req.user.id) };
    if (req.body?.status !== undefined) {
      patch.adminStatus = req.body.status === 'suspended' ? 'suspended' : 'active';
    }
    if (req.body?.roleId !== undefined) {
      const roleId = String(req.body.roleId);
      if (DEFAULT_ADMIN_ROLES[roleId]) {
        patch.adminRole = roleId;
        patch.customPermissions = [];
      } else {
        const customRole = await store().findById('adminRoles', roleId);
        if (!customRole) return res.status(400).json({ message: 'الدور غير موجود' });
        patch.adminRole = 'custom';
        patch.customRoleId = Number(customRole.id);
        patch.customPermissions = customRole.permissions || [];
      }
      patch.deniedPermissions = [];
    }
    if (Array.isArray(req.body?.customPermissions)) {
      patch.customPermissions = [...new Set(req.body.customPermissions)]
        .filter((permission) => ADMIN_PERMISSIONS.includes(permission));
    }
    const updated = await store().update('users', user.id, patch);
    await audit(req, 'staff.updated', 'user', user.id, patch);
    publish('admin:permissions.updated', { adminId: Number(user.id) });
    res.json({
      id: Number(updated.id),
      name: updated.name,
      email: updated.email,
      role: updated.adminRole,
      status: updated.adminStatus || 'active',
      permissions: effectivePermissions(updated),
    });
  });

  app.get('/api/admin/search', auth, permit('dashboard.read'), async (req, res) => {
    const q = String(req.query.q || '').trim().toLowerCase();
    if (q.length < 2) return res.json({ items: [] });
    const [users, fields, bookings] = await Promise.all([
      store().find('users'),
      store().find('fields'),
      hydratedBookings({ q }),
    ]);
    const items = [
      ...bookings.slice(0, 10).map((booking) => ({
        id: booking.id,
        type: 'bookings',
        label: `${booking.referenceCode || booking.id} · ${booking.fieldName}`,
        path: `/bookings/${booking.id}`,
      })),
      ...users.filter((user) => `${user.name || ''} ${user.email || ''} ${user.phone || ''}`
        .toLowerCase().includes(q)).slice(0, 10).map((user) => ({
        id: Number(user.id),
        type: 'users',
        label: user.name || user.email,
        path: `/users?q=${encodeURIComponent(user.email || user.phone || user.name || user.id)}`,
      })),
      ...fields.filter((field) => `${field.name || ''} ${field.address || ''}`
        .toLowerCase().includes(q)).slice(0, 10).map((field) => ({
        id: publicNumericId(field),
        type: 'fields',
        label: field.name,
        path: '/fields',
      })),
    ].slice(0, 25);
    res.json({ items });
  });

  return {
    permit,
    audit,
    publish,
    createAlert,
    closeEntityAlerts,
    maintenanceConflict,
    bookingConflict,
    expandMaintenanceBlock,
    hydratedBookings,
    paginate,
    effectivePermissions,
  };
}

module.exports = {
  ADMIN_PERMISSIONS,
  DEFAULT_ADMIN_ROLES,
  effectivePermissions,
  hasPermission,
  setupAdminBackend,
};
