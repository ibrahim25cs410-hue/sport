const mongoose = require('mongoose');

const BOOKING_STATUSES = ['pending', 'confirmed', 'rejected', 'completed', 'approved', 'cancelled'];

const bookingSchema = new mongoose.Schema({
  id: { type: Number, required: true, unique: true, index: true },

  // Task 3 — stadium bookings (userId/stadiumId map to User.id / Stadium.id)
  userId: { type: Number, required: true, ref: 'User', index: true },
  stadiumId: { type: Number, ref: 'Stadium', index: true },
  startTime: { type: Date, required: true, index: true },
  endTime: { type: Date },
  status: {
    type: String,
    enum: BOOKING_STATUSES,
    default: 'pending',
    index: true,
  },
  ownerId: { type: Number, ref: 'User', index: true },

  // Legacy field bookings (Flutter app)
  fieldId: { type: Number, ref: 'Field', index: true },
  hours: { type: Number, min: 1, default: 1 },
  totalPrice: { type: Number, min: 0, default: 0 },
  paymentStatus: { type: String, default: 'unpaid' },
  paymentMethod: { type: String, default: 'online' },
  referenceCode: { type: String, default: null },
}, { timestamps: true });

bookingSchema.index({ stadiumId: 1, startTime: 1, endTime: 1 });

bookingSchema.set('toJSON', {
  transform(_doc, ret) {
    delete ret._id;
    delete ret.__v;
    if (ret.startTime) ret.startTime = new Date(ret.startTime).toISOString();
    if (ret.endTime) ret.endTime = new Date(ret.endTime).toISOString();
    return ret;
  },
});

module.exports = mongoose.model('Booking', bookingSchema);
module.exports.BOOKING_STATUSES = BOOKING_STATUSES;
