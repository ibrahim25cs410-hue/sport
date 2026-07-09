const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  id: { type: Number, required: true, unique: true, index: true },
  name: { type: String, required: true, trim: true, maxlength: 120 },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
    maxlength: 254,
    index: true,
  },
  password: { type: String, required: true, select: false, minlength: 6 },
  role: { type: String, enum: ['user', 'owner'], default: 'user', index: true },
  phone: { type: String, default: '' },
  province: { type: String, default: 'نينوى' },
  image: { type: String, default: null },
  loyaltyPoints: { type: Number, default: 0, min: 0 },
}, { timestamps: true });

userSchema.set('toJSON', {
  transform(_doc, ret) {
    delete ret._id;
    delete ret.__v;
    delete ret.password;
    delete ret.createdAt;
    delete ret.updatedAt;
    return ret;
  },
});

module.exports = mongoose.model('User', userSchema);
