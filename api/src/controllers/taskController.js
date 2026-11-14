const Task = require('../models/Task');

exports.createTask = async (req, res) => {
  try {
    const { projectId, title, description, priority, startDate, dueDate } = req.body;
    if (!projectId || !title) return res.status(400).json({ success: false, message: 'Vui lòng nhập tên công việc' });
    const task = await Task.create({
      project: projectId,
      title,
      description: description || '',
      priority: priority || 'Medium',
      startDate: startDate || null,
      dueDate: dueDate || null,
      createdBy: req.user.id
    });
    res.status(201).json({ success: true, message: 'Tạo công việc thành công', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

// B6 & B7 - Lấy danh sách công việc kèm Tìm kiếm, Lọc & Sắp xếp
exports.getTasksByProject = async (req, res) => {
  try {
    const { search, status, priority, sortBy } = req.query;
    const filter = { project: req.params.projectId };
    if (search && search.trim() !== '') filter.title = { $regex: search.trim(), $options: 'i' };
    if (status && status !== 'All') filter.status = status;
    if (priority && priority !== 'All') filter.priority = priority;

    let tasks = await Task.find(filter).sort({ createdAt: -1 });

    if (sortBy === 'dueDate') {
      tasks.sort((a, b) => {
        if (!a.dueDate) return 1;
        if (!b.dueDate) return -1;
        return new Date(a.dueDate) - new Date(b.dueDate);
      });
    } else if (sortBy === 'priority') {
      const rank = { High: 1, Medium: 2, Low: 3 };
      tasks.sort((a, b) => (rank[a.priority] || 4) - (rank[b.priority] || 4));
    }

    res.json({ success: true, data: tasks });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateTaskStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const task = await Task.findByIdAndUpdate(req.params.id, { status }, { new: true });
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    res.json({ success: true, message: 'Đã cập nhật trạng thái công việc', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateTaskPriority = async (req, res) => {
  try {
    const { priority } = req.body;
    const task = await Task.findByIdAndUpdate(req.params.id, { priority }, { new: true });
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    res.json({ success: true, message: 'Đã cập nhật mức độ ưu tiên', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateTaskDates = async (req, res) => {
  try {
    const { startDate, dueDate } = req.body;
    if (startDate && dueDate && new Date(startDate) > new Date(dueDate)) {
      return res.status(400).json({ success: false, message: 'Ngày bắt đầu không được lớn hơn hạn hoàn thành' });
    }
    const task = await Task.findByIdAndUpdate(
      req.params.id,
      { startDate: startDate || null, dueDate: dueDate || null },
      { new: true }
    );
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    res.json({ success: true, message: 'Đã cập nhật thời gian công việc', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
