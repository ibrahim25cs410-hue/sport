const mongoose = require('mongoose');

const stadiumSchema = new mongoose.Schema({
  id: { type: Number, required: true, unique: true, index: true },
  name: { type: String, required: true, trim: true, maxlength: 160 },
  address: { type: String, default: '', trim: true },
  phone: { type: String, default: '', trim: true },
  image: { type: String, default: null },
  pricePerHour: { type: Number, default: 0, min: 0 },
  ownerId: { type: Number, required: true, index: true },
  description: { type: String, default: '', maxlength: 1000 },
  latitude: { type: Number, default: null },
  longitude: { type: Number, default: null },
  isActive: { type: Boolean, default: true, index: true },
}, { timestamps: true });

stadiumSchema.index({ ownerId: 1, name: 1 });

stadiumSchema.set('toJSON', {
  transform(_doc, ret) {
    delete ret._id;
    delete ret.__v;
    delete ret.createdAt;
    delete ret.updatedAt;
    return ret;
  },
});

module.exports = mongoose.model('Stadium', stadiumSchema);
