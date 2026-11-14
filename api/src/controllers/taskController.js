const Task = require('../models/Task');

exports.createTask = async (req, res) => {
  try {
    const { projectId, title, description } = req.body;
    if (!projectId || !title) return res.status(400).json({ success: false, message: 'Vui lòng nhập tên công việc' });
    const task = await Task.create({ project: projectId, title, description: description || '', createdBy: req.user.id });
    res.status(201).json({ success: true, message: 'Tạo công việc thành công', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.getTasksByProject = async (req, res) => {
  try {
    const tasks = await Task.find({ project: req.params.projectId }).sort({ createdAt: -1 });
    res.json({ success: true, data: tasks });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

// B3 - Cập nhật trạng thái công việc
exports.updateTaskStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const task = await Task.findByIdAndUpdate(req.params.id, { status }, { new: true });
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    res.json({ success: true, message: 'Đã cập nhật trạng thái công việc', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
