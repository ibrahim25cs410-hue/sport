const mongoose = require('mongoose');

const fieldSchema = new mongoose.Schema({
  id: { type: Number, required: true, unique: true, index: true },
  name: { type: String, required: true, trim: true },
  address: { type: String, default: '' },
  phone: { type: String, default: '' },
  image: { type: String, default: null },
  pricePerHour: { type: Number, default: 0, min: 0 },
  ownerId: { type: Number, required: true, index: true },
  averageRating: { type: Number, default: 0 },
  reviewCount: { type: Number, default: 0 },
  latitude: { type: Number, default: null },
  longitude: { type: Number, default: null },
  isActive: { type: Boolean, default: true, index: true },
}, { timestamps: true });

fieldSchema.set('toJSON', {
  transform(_doc, ret) {
    delete ret._id;
    delete ret.__v;
    delete ret.createdAt;
    delete ret.updatedAt;
    return ret;
  },
});

module.exports = mongoose.model('Field', fieldSchema);
