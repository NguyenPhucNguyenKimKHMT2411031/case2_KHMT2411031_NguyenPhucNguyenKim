const Task = require('../models/Task');

// GET /api/tasks/:id/assignees - Danh sách người được giao
exports.getAssignees = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id)
      .populate('assigneeIds', 'fullName email avatarUrl')
      .populate('primaryAssigneeId', 'fullName email');
    res.json({ assignees: task.assigneeIds, primaryAssignee: task.primaryAssigneeId });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi lấy danh sách giao việc', error: err.message });
  }
};

// POST /api/tasks/:id/assignees - Giao việc cho 1 hoặc nhiều người (Chỉ Owner)
exports.assignTask = async (req, res) => {
  try {
    const { assigneeIds, primaryAssigneeId } = req.body;
    const task = req.task;
    if (assigneeIds) task.assigneeIds = assigneeIds;
    if (primaryAssigneeId) task.primaryAssigneeId = primaryAssigneeId;
    await task.save();
    res.json({ message: 'Giao việc thành công', task });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi giao việc', error: err.message });
  }
};

// PATCH /api/tasks/:id/assignees/:userId - Cập nhật người phụ trách chính (Chỉ Owner)
exports.updatePrimaryAssignee = async (req, res) => {
  try {
    const task = req.task;
    task.primaryAssigneeId = req.params.userId;
    await task.save();
    res.json({ message: 'Cập nhật người phụ trách chính thành công', task });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi cập nhật người phụ trách chính', error: err.message });
  }
};

// DELETE /api/tasks/:id/assignees/:userId - Hủy giao việc cho 1 người (Chỉ Owner)
exports.removeAssignee = async (req, res) => {
  try {
    const { userId } = req.params;
    const task = req.task;
    task.assigneeIds = task.assigneeIds.filter(id => id.toString() !== userId);
    if (task.primaryAssigneeId && task.primaryAssigneeId.toString() === userId) {
      task.primaryAssigneeId = null;
    }
    await task.save();
    res.json({ message: 'Hủy giao việc thành công', task });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi hủy giao việc', error: err.message });
  }
};