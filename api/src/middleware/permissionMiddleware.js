const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

const checkTaskPermission = (requiredPermission = 'viewer') => {
  return async (req, res, next) => {
    try {
      const taskId = req.params.id;
      const userId = req.user._id;

      const task = await Task.findById(taskId);
      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc' });
      }

      if (task.createdBy.toString() === userId.toString()) {
        req.task = task;
        req.userRole = 'owner';
        return next();
      }

      if (requiredPermission === 'owner') {
        return res.status(403).json({ message: 'Chỉ người tạo mới có quyền thao tác này' });
      }

      const share = await TaskShare.findOne({ taskId, userId });
      const isAssignee = task.assigneeIds && task.assigneeIds.some(id => id.toString() === userId.toString());

      if (requiredPermission === 'editor') {
        if (share && share.permission === 'editor') {
          req.task = task;
          req.userRole = 'editor';
          return next();
        }
        return res.status(403).json({ message: 'Bạn cần quyền Editor để thao tác' });
      }

      if (requiredPermission === 'viewer') {
        if (share || isAssignee) {
          req.task = task;
          req.userRole = share ? share.permission : 'viewer';
          return next();
        }
        return res.status(403).json({ message: 'Bạn không có quyền xem công việc này' });
      }

      return res.status(403).json({ message: 'Truy cập bị từ chối' });
    } catch (err) {
      return res.status(500).json({ message: 'Lỗi kiểm tra phân quyền', error: err.message });
    }
  };
};

module.exports = { checkTaskPermission };