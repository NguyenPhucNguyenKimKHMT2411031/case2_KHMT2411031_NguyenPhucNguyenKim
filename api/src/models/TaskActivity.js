const mongoose = require('mongoose');

const taskActivitySchema = new mongoose.Schema({
  task: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true },
  actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  action: { type: String, required: true },
  detail: { type: String, default: '' }
}, { timestamps: true });

module.exports = mongoose.model('TaskActivity', taskActivitySchema);
