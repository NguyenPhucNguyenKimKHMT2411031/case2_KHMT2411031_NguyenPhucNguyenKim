const mongoose = require('mongoose');
const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

const POPULATE = [
  { path: 'createdBy', select: 'fullName email' },
  { path: 'assigneeIds', select: 'fullName email' },
  { path: 'primaryAssigneeId', select: 'fullName email' },
];

exports.getTasks = async (req, res, next) => {
  try {
    const uid = req.user._id;
    const shares = await TaskShare.find({ userId: uid }).select('taskId');
    const sharedIds = shares.map((s) => s.taskId);

    const scopes = {
      created: { createdBy: uid },
      assigned: { assigneeIds: uid },
      shared: { _id: { $in: sharedIds } },
    };

    const { scope, status, priority, q } = req.query;
    const filter = scopes[scope] ? { ...scopes[scope] } : { $or: Object.values(scopes) };
    if (status) filter.status = status;
    if (priority) filter.priority = priority;
    if (q) {
      filter.title = { $regex: q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), $options: 'i' };
    }

    const tasks = await Task.find(filter).populate(POPULATE).sort({ createdAt: -1 });
    res.status(200).json(tasks);
  } catch (e) {
    next(e);
  }
};