const Task = require('../models/Task');

exports.createTask = async (req, res) => {
  try {
    const { title, description, startDate, dueDate, priority, status } = req.body;
    const newTask = new Task({
      title,
      description,
      startDate,
      dueDate,
      priority: priority || 'medium',
      status: status || 'todo',
      createdBy: req.user._id,
    });
    await newTask.save();
    return res.status(201).json({ message: 'Tạo công việc thành công', task: newTask });
  } catch (err) {
    return res.status(500).json({ message: 'Lỗi tạo công việc', error: err.message });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const updatedTask = await Task.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!updatedTask) return res.status(404).json({ message: 'Không tìm thấy công việc' });
    return res.json({ message: 'Cập nhật công việc thành công', task: updatedTask });
  } catch (err) {
    return res.status(500).json({ message: 'Lỗi cập nhật công việc', error: err.message });
  }
};

exports.deleteTask = async (req, res) => {
  try {
    const deletedTask = await Task.findByIdAndDelete(req.params.id);
    if (!deletedTask) return res.status(404).json({ message: 'Không tìm thấy công việc' });
    return res.json({ message: 'Xóa công việc thành công' });
  } catch (err) {
    return res.status(500).json({ message: 'Lỗi xóa công việc', error: err.message });
  }
};

exports.updateStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const updatedTask = await Task.findByIdAndUpdate(req.params.id, { status }, { new: true });
    if (!updatedTask) return res.status(404).json({ message: 'Không tìm thấy công việc' });
    return res.json({ message: 'Cập nhật trạng thái thành công', task: updatedTask });
  } catch (err) {
    return res.status(500).json({ message: 'Lỗi cập nhật trạng thái', error: err.message });
  }
};