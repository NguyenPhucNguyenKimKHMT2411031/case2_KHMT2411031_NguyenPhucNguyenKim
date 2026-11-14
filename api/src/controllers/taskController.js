const Task = require('../models/Task');
const User = require('../models/User');

exports.createTask = async (req, res) => {
  try {
    const { projectId, title, description, priority, startDate, dueDate } = req.body;
    if (!projectId || !title) return res.status(400).json({ success: false, message: 'Vui lòng nhập tên công việc' });
    const task = await Task.create({ project: projectId, title, description: description || '', priority: priority || 'Medium', startDate: startDate || null, dueDate: dueDate || null, createdBy: req.user.id });
    res.status(201).json({ success: true, message: 'Tạo công việc thành công', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.getTasksByProject = async (req, res) => {
  try {
    const { search, status, priority, sortBy } = req.query;
    const filter = { project: req.params.projectId };
    if (search && search.trim() !== '') filter.title = { $regex: search.trim(), $options: 'i' };
    if (status && status !== 'All') filter.status = status;
    if (priority && priority !== 'All') filter.priority = priority;
    let tasks = await Task.find(filter)
      .populate('leadAssignee', 'fullName email')
      .populate('assignees.user', 'fullName email')
      .populate('sharedWith.user', 'fullName email')
      .sort({ createdAt: -1 });
    if (sortBy === 'dueDate') tasks.sort((a, b) => (!a.dueDate ? 1 : !b.dueDate ? -1 : new Date(a.dueDate) - new Date(b.dueDate)));
    else if (sortBy === 'priority') { const rank = { High: 1, Medium: 2, Low: 3 }; tasks.sort((a, b) => (rank[a.priority] || 4) - (rank[b.priority] || 4)); }
    res.json({ success: true, data: tasks });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateTaskStatus = async (req, res) => {
  try {
    const task = await Task.findByIdAndUpdate(req.params.id, { status: req.body.status }, { new: true });
    res.json({ success: true, message: 'Đã cập nhật trạng thái', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateTaskPriority = async (req, res) => {
  try {
    const task = await Task.findByIdAndUpdate(req.params.id, { priority: req.body.priority }, { new: true });
    res.json({ success: true, message: 'Đã cập nhật ưu tiên', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateTaskDates = async (req, res) => {
  try {
    const { startDate, dueDate } = req.body;
    const task = await Task.findByIdAndUpdate(req.params.id, { startDate: startDate || null, dueDate: dueDate || null }, { new: true });
    res.json({ success: true, message: 'Đã cập nhật thời gian', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.assignUsersByEmail = async (req, res) => {
  try {
    const { emails, permission } = req.body;
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    const emailList = Array.isArray(emails) ? emails : String(emails || '').split(',');
    let added = 0;
    for (const raw of emailList) {
      const user = await User.findOne({ email: raw.trim().toLowerCase() });
      if (user && !task.assignees.some(a => a.user.toString() === user._id.toString())) { task.assignees.push({ user: user._id, permission: permission || 'edit' }); added++; }
    }
    if (added === 0) return res.status(400).json({ success: false, message: 'Email không hợp lệ hoặc đã được giao' });
    await task.save();
    res.json({ success: true, message: `Đã giao việc cho ${added} thành viên`, data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.setLeadAssignee = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    const user = await User.findOne({ email: (req.body.email || '').trim().toLowerCase() });
    if (!task || !user) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc hoặc email người dùng' });
    task.leadAssignee = user._id;
    if (!task.assignees.some(a => a.user.toString() === user._id.toString())) task.assignees.push({ user: user._id, permission: 'edit' });
    await task.save();
    res.json({ success: true, message: `Đã chỉ định ${user.fullName} làm phụ trách chính`, data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

// C3 - Chia sẻ công việc theo email
exports.shareTaskByEmail = async (req, res) => {
  try {
    const { emails, permission } = req.body;
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    const emailList = Array.isArray(emails) ? emails : String(emails || '').split(',');
    let sharedCount = 0;
    for (const raw of emailList) {
      const user = await User.findOne({ email: raw.trim().toLowerCase() });
      if (user && !task.sharedWith.some(s => s.user.toString() === user._id.toString())) {
        task.sharedWith.push({ user: user._id, permission: permission || 'view' });
        sharedCount++;
      }
    }
    if (sharedCount === 0) return res.status(400).json({ success: false, message: 'Email không tồn tại hoặc đã được chia sẻ' });
    await task.save();
    res.json({ success: true, message: `Đã chia sẻ công việc cho ${sharedCount} người`, data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
