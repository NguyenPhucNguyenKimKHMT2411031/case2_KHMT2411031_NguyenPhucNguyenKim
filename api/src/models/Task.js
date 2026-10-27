const mongoose = require('mongoose');
const { ObjectId } = mongoose.Schema.Types;

const taskSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    createdBy: { type: ObjectId, ref: 'User', required: true },
    assigneeIds: [{ type: ObjectId, ref: 'User' }],
    primaryAssigneeId: { type: ObjectId, ref: 'User' },
    startDate: { type: Date },
    dueDate: { type: Date },
    priority: { type: String, enum: ['low', 'medium', 'high'], default: 'medium' },
    status: { type: String, enum: ['todo', 'in_progress', 'completed'], default: 'todo' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Task', taskSchema);