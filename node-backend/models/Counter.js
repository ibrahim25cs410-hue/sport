const mongoose = require('mongoose');

const counterSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  n: { type: Number, default: 0 },
});

counterSchema.statics.nextId = async function (name) {
  const doc = await this.findByIdAndUpdate(
    name,
    { $inc: { n: 1 } },
    { new: true, upsert: true },
  );
  return doc.n;
};

module.exports = mongoose.model('Counter', counterSchema);
