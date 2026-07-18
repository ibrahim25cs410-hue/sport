const REQUIRED_INDEXES = Object.freeze({
  users: ['user_email_unique'],
  bookings: ['booking_idempotency_unique', 'booking_field_start'],
  bookingclaims: ['booking_claim_slot_unique', 'booking_claim_booking'],
  paymentcredits: ['payment_credit_idempotency'],
  wallettransactions: ['wallet_transaction_idempotency'],
  settlements: ['settlement_idempotency'],
  admininvitations: ['admin_invitation_token_unique', 'admin_invitation_email_status'],
});

function buildModels(mongoose) {
  const { Schema } = mongoose;
  // Existing Mongo documents are never rewritten or stripped by these schemas. Strict mode applies
  // when constructing or updating documents, so unknown future writes fail instead of silently
  // becoming production data. Legacy fields still used by readers are declared explicitly below.
  const opts = { strict: 'throw', id: false, versionKey: false };
  const common = { id: { type: Number, min: 1, index: true } };
  const dateString = { type: String };
  const auditDetailsSchema = new Schema({
    statusCode: Number,
    adminRole: String,
    customPermissions: [String],
    deniedPermissions: [String],
    permissions: [String],
    fieldId: Number,
    userId: Number,
    ownerId: Number,
    conflicts: [Number],
    bookingIds: [Number],
    succeeded: Number,
    format: String,
    rows: Number,
    amountIqd: Number,
    status: String,
    from: String,
    to: String,
    email: String,
    roleId: String,
    invitedBy: Number,
    startTime: dateString,
    endTime: dateString,
    hours: Number,
    totalPrice: Number,
    fieldPublicId: Number,
    updatedByAdminId: Number,
    paymentStatus: String,
    paymentMethod: String,
    adminNotes: String,
    reason: String,
    notes: String,
    recurrence: String,
    recurrenceEnd: dateString,
    method: String,
    reference: String,
    evidenceUrl: String,
    evidenceNote: String,
    approvalNote: String,
    paidAt: dateString,
    paidBy: Number,
    paymentEvidence: { reference: String, url: String, note: String },
    voidReason: String,
    voidedAt: dateString,
    voidedBy: Number,
    readBy: [Number],
    assignedTo: Number,
    assignedAt: dateString,
    assignedBy: Number,
    snoozeUntil: dateString,
    actionUrl: String,
    entityType: String,
    entityId: String,
    resolutionReason: String,
    resolvedAt: dateString,
    resolvedBy: Number,
    dismissedAt: dateString,
    dismissedBy: Number,
    adminStatus: String,
    customRoleId: Number,
    sessionVersion: Number,
    sessionsRevokedAt: dateString,
    updatedAt: dateString,
    updatedBy: Number,
  }, { strict: 'throw', _id: false, versionKey: false });
  const schemas = {
    users: new Schema({
      ...common,
      name: { type: String, trim: true, maxlength: 200 },
      email: { type: String, trim: true, lowercase: true, maxlength: 320 },
      password: { type: String, select: true },
      phone: { type: String, maxlength: 100 },
      province: { type: String, maxlength: 200 },
      image: String,
      role: { type: String, enum: ['user', 'owner', 'admin'] },
      loyaltyPoints: { type: Number, default: 0 },
      sessionVersion: { type: Number, default: 0, min: 0 },
      sessionsRevokedAt: dateString,
      walletBalance: { type: Number, default: 0 },
      walletStatus: { type: String, enum: ['active', 'blocked'] },
      appliedWalletKeys: [{ type: String }],
      fcmToken: String,
      fcmUpdatedAt: dateString,
      adminRole: String,
      customRoleId: Number,
      customPermissions: [String],
      deniedPermissions: [String],
      adminStatus: { type: String, enum: ['active', 'suspended'] },
      permissionsUpdatedAt: dateString,
      permissionsUpdatedBy: Number,
      updatedBy: Number,
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    fields: new Schema({
      ...common,
      name: { type: String, trim: true, maxlength: 200 },
      address: { type: String, maxlength: 1000 },
      phone: { type: String, maxlength: 100 },
      image: String,
      ownerId: { type: Number, min: 1 },
      pricePerHour: { type: Number, min: 0 },
      averageRating: { type: Number, min: 0, max: 5 },
      reviewCount: { type: Number, min: 0 },
      latitude: Number,
      longitude: Number,
      isActive: { type: Boolean, default: true },
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    bookings: new Schema({
      ...common,
      // Legacy field ids may be numeric in Mongo. String casting preserves comparison compatibility
      // because all API ownership/lookup paths already normalize ids through sameId()/Number().
      fieldId: String,
      fieldPublicId: { type: Number, min: 1 },
      ownerId: { type: Number, min: 0 },
      userId: { type: Number, min: 1 },
      fieldName: String,
      customerName: String,
      customerPhone: String,
      startTime: dateString,
      hours: { type: Number, min: 1, max: 24 },
      totalPrice: { type: Number, min: 0 },
      status: { type: String, enum: ['pending', 'approved', 'completed', 'cancelled', 'rejected'] },
      paymentStatus: { type: String, enum: ['unpaid', 'pay_at_venue', 'paid', 'failed', 'refunded'] },
      paymentMethod: { type: String, enum: ['cash', 'online', 'card', 'wallet'] },
      referenceCode: String,
      source: { type: String, enum: ['app', 'admin'] },
      adminNotes: String,
      createdByAdminId: Number,
      updatedByAdminId: Number,
      paidByAdminId: Number,
      paymentConfirmedBy: Number,
      paidAt: dateString,
      walletCredited: Boolean,
      walletCreditedAt: dateString,
      idempotencyKey: { type: String, maxlength: 200 },
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    notifications: new Schema({
      ...common, userId: Number, title: String, message: String, isRead: Boolean,
      createdAt: dateString, updatedAt: dateString,
    }, opts),
    reviews: new Schema({
      ...common, fieldId: String, fieldPublicId: Number, userId: Number,
      rating: { type: Number, min: 1, max: 5 }, comment: String,
      createdAt: dateString, updatedAt: dateString,
    }, opts),
    walletTransactions: new Schema({
      ...common,
      ownerId: Number,
      amount: Number,
      type: String,
      typeLabel: String,
      description: String,
      bookingId: Number,
      bookingReference: String,
      adminNote: String,
      idempotencyKey: String,
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    auditLogs: new Schema({
      ...common,
      actorId: Number,
      actorName: String,
      actorEmail: String,
      action: String,
      resourceType: String,
      resourceId: String,
      details: { type: auditDetailsSchema },
      requestId: String,
      ip: String,
      ipAddress: String,
      userAgent: String,
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    maintenanceBlocks: new Schema({
      ...common,
      fieldId: String,
      fieldName: String,
      startTime: dateString,
      endTime: dateString,
      reason: String,
      notes: String,
      recurrence: { type: String, enum: ['none', 'daily', 'weekly'] },
      recurrenceEnd: dateString,
      status: { type: String, enum: ['active', 'cancelled'] },
      createdBy: Number,
      cancelledBy: Number,
      cancelledAt: dateString,
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    settlements: new Schema({
      ...common,
      ownerId: Number,
      ownerName: String,
      amountIqd: Number,
      grossAmount: Number,
      platformFee: Number,
      netAmount: Number,
      status: { type: String, enum: ['pending', 'approved', 'paid', 'void'] },
      periodStart: dateString,
      periodEnd: dateString,
      method: String,
      reference: String,
      evidenceUrl: String,
      evidenceNote: String,
      notes: String,
      idempotencyKey: String,
      createdBy: Number,
      approvedAt: dateString,
      approvedBy: Number,
      approvalNote: String,
      paidAt: dateString,
      paidBy: Number,
      paymentEvidence: {
        reference: String,
        url: String,
        note: String,
      },
      voidReason: String,
      voidedAt: dateString,
      voidedBy: Number,
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    adminPreferences: new Schema({
      ...common,
      adminId: Number,
      locale: String,
      timezone: String,
      theme: String,
      // These are intentionally flexible per-admin UI metadata, not critical business records.
      dashboard: Schema.Types.Mixed,
      notifications: Schema.Types.Mixed,
      defaultFilters: Schema.Types.Mixed,
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    adminAlerts: new Schema({
      ...common,
      type: String,
      severity: String,
      title: String,
      message: String,
      // Alert payload is non-critical event metadata with source-specific keys.
      data: Schema.Types.Mixed,
      dedupeKey: String,
      actionUrl: String,
      entityType: String,
      entityId: String,
      assignedTo: Number,
      assignedAt: dateString,
      assignedBy: Number,
      snoozeUntil: dateString,
      status: { type: String, enum: ['open', 'snoozed', 'resolved', 'dismissed'] },
      readBy: [Number],
      resolutionReason: String,
      resolvedAt: dateString,
      resolvedBy: Number,
      dismissedAt: dateString,
      dismissedBy: Number,
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    paymentCredits: new Schema({
      ...common,
      bookingId: Number,
      ownerId: Number,
      grossAmountIqd: Number,
      commissionRate: Number,
      commissionAmountIqd: Number,
      netAmountIqd: Number,
      status: { type: String, enum: ['processing', 'completed', 'failed'] },
      idempotencyKey: String,
      legacy: Boolean,
      migrationId: String,
      completedAt: dateString,
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    adminRoles: new Schema({
      ...common,
      name: String,
      description: String,
      permissions: [String],
      status: { type: String, enum: ['active', 'deleted'] },
      createdBy: Number,
      updatedBy: Number,
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
    adminInvitations: new Schema({
      ...common,
      name: { type: String, trim: true, maxlength: 200 },
      email: { type: String, trim: true, lowercase: true, maxlength: 320 },
      roleId: String,
      roleName: String,
      permissions: [String],
      status: { type: String, enum: ['pending', 'accepted', 'revoked', 'expired'] },
      invitedBy: Number,
      tokenHash: { type: String, maxlength: 64 },
      expiresAt: dateString,
      acceptedAt: dateString,
      deliveryStatus: { type: String, enum: ['pending', 'sent', 'failed', 'not_configured'] },
      deliveryProvider: String,
      deliveryMessageId: String,
      deliveryError: String,
      createdAt: dateString,
      updatedAt: dateString,
    }, opts),
  };

  schemas.users.index({ email: 1 }, {
    unique: true, partialFilterExpression: { email: { $type: 'string' } }, name: 'user_email_unique',
  });
  schemas.bookings.index({ idempotencyKey: 1 }, {
    unique: true, partialFilterExpression: { idempotencyKey: { $type: 'string' } }, name: 'booking_idempotency_unique',
  });
  schemas.bookings.index({ fieldPublicId: 1, startTime: 1, status: 1 }, { name: 'booking_field_start' });
  schemas.paymentCredits.index({ idempotencyKey: 1 }, { unique: true, sparse: true, name: 'payment_credit_idempotency' });
  schemas.walletTransactions.index({ idempotencyKey: 1 }, { unique: true, sparse: true, name: 'wallet_transaction_idempotency' });
  schemas.settlements.index({ idempotencyKey: 1 }, { unique: true, sparse: true, name: 'settlement_idempotency' });
  schemas.auditLogs.index({ createdAt: -1 }, { name: 'audit_created_at' });
  schemas.adminAlerts.index({ status: 1, createdAt: -1 }, { name: 'alerts_status_created' });
  schemas.adminInvitations.index({ tokenHash: 1 }, {
    unique: true, partialFilterExpression: { tokenHash: { $type: 'string' } }, name: 'admin_invitation_token_unique',
  });
  schemas.adminInvitations.index({ email: 1, status: 1 }, { name: 'admin_invitation_email_status' });

  const modelNames = {
    users: 'User', fields: 'Field', bookings: 'Booking', notifications: 'Notification',
    reviews: 'Review', walletTransactions: 'WalletTransaction', auditLogs: 'AuditLog',
    maintenanceBlocks: 'MaintenanceBlock', settlements: 'Settlement',
    adminPreferences: 'AdminPreference', adminAlerts: 'AdminAlert',
    paymentCredits: 'PaymentCredit', adminRoles: 'AdminRole', adminInvitations: 'AdminInvitation',
  };
  const models = Object.fromEntries(Object.entries(schemas).map(([key, schema]) => [
    key, mongoose.models[modelNames[key]] || mongoose.model(modelNames[key], schema),
  ]));

  const claimSchema = new Schema({
    slotKey: { type: String, required: true },
    bookingId: { type: Number, required: true },
    reservationId: { type: String, required: true },
    createdAt: { type: Date, default: Date.now },
  }, { strict: 'throw', versionKey: false });
  claimSchema.index({ slotKey: 1 }, { unique: true, name: 'booking_claim_slot_unique' });
  claimSchema.index({ bookingId: 1 }, { name: 'booking_claim_booking' });
  models.bookingClaims = mongoose.models.BookingClaim || mongoose.model('BookingClaim', claimSchema);
  return models;
}

async function checkRequiredIndexes(models) {
  const missing = [];
  for (const [collection, names] of Object.entries(REQUIRED_INDEXES)) {
    const modelKey = collection === 'bookingclaims' ? 'bookingClaims'
      : Object.keys(models).find((key) => models[key].collection.collectionName === collection);
    if (!modelKey) {
      missing.push(...names.map((name) => `${collection}.${name}`));
      continue;
    }
    const existing = new Set((await models[modelKey].collection.indexes()).map((index) => index.name));
    missing.push(...names.filter((name) => !existing.has(name)).map((name) => `${collection}.${name}`));
  }
  return missing;
}

module.exports = { REQUIRED_INDEXES, buildModels, checkRequiredIndexes };
