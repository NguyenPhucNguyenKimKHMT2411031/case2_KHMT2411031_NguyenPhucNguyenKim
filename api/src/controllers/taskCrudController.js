const Task = require('../models/Task');
const { validateTaskBody } = require('../validators/taskValidator');

const uidOf = (req) => req.user?._id || req.user?.id || req.userId;

// POST /tasks
exports.createTask = async (req, res, next) => {
  try {
    const { errors, data } = validateTaskBody(req.body);
    if (errors.length) return res.status(400).json({ message: errors[0], errors });
    if (data.startDate && data.dueDate && data.dueDate < data.startDate) {
      return res.status(400).json({ message: 'Hạn hoàn thành phải sau ngày bắt đầu' });
    }
    const task = await Task.create({
      ...data,
      status: data.status || 'todo',
      priority: data.priority || 'medium',
      createdBy: uidOf(req),
      assigneeIds: [],
      primaryAssigneeId: null,
    });
    res.status(201).json({ task });
  } catch (err) {
    next(err);
  }
};