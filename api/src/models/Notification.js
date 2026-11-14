const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  type: { type: String, enum: ['assign', 'lead', 'share', 'deadline', 'system'], default: 'system' },
  title: { type: String, required: true },
  message: { type: String, required: true },
  task: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', default: null },
  isRead: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
