const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;

const taskShareSchema = new mongoose.Schema(
  {
    taskId: { type: ObjectId, ref: 'Task', required: true },
    userId: { type: ObjectId, ref: 'User', required: true },
    permission: { type: String, enum: ['viewer', 'editor'], default: 'viewer' },
    sharedBy: { type: ObjectId, ref: 'User' },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);
taskShareSchema.index({ taskId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('TaskShare', taskShareSchema);