const Task = require('../models/Task');
const User = require('../models/User');
const Project = require('../models/Project');

// C4 - Hàm kiểm tra quyền chỉnh sửa (edit) của user trên công việc
async function canEditTask(task, userId) {
  if (!task || !userId) return false;
  const uid = userId.toString();
  if (task.createdBy && task.createdBy.toString() === uid) return true;
  if (task.leadAssignee && task.leadAssignee.toString() === uid) return true;
  const proj = await Project.findById(task.project);
  if (proj && proj.owner && proj.owner.toString() === uid) return true;
  if (task.assignees.some(a => a.user.toString() === uid && a.permission === 'edit')) return true;
  if (task.sharedWith.some(s => s.user.toString() === uid && s.permission === 'edit')) return true;
  return false;
}

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
    const enriched = await Promise.all(tasks.map(async t => ({ ...t.toObject(), canEdit: await canEditTask(t, req.user.id) })));
    res.json({ success: true, data: enriched });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
exports.updateTaskStatus = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn chỉ có quyền xem (View), không được chỉnh sửa' });
    task.status = req.body.status;
    await task.save();
    res.json({ success: true, message: 'Đã cập nhật trạng thái', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateTaskPriority = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn chỉ có quyền xem (View), không được chỉnh sửa' });
    task.priority = req.body.priority;
    await task.save();
    res.json({ success: true, message: 'Đã cập nhật ưu tiên', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateTaskDates = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn chỉ có quyền xem (View), không được chỉnh sửa' });
    task.startDate = req.body.startDate || null;
    task.dueDate = req.body.dueDate || null;
    await task.save();
    res.json({ success: true, message: 'Đã cập nhật thời gian', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.assignUsersByEmail = async (req, res) => {
  try {
    const { emails, permission } = req.body;
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn không có quyền giao việc' });
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
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn không có quyền chỉ định phụ trách chính' });
    const user = await User.findOne({ email: (req.body.email || '').trim().toLowerCase() });
    if (!user) return res.status(404).json({ success: false, message: 'Không tìm thấy email người dùng' });
    task.leadAssignee = user._id;
    if (!task.assignees.some(a => a.user.toString() === user._id.toString())) task.assignees.push({ user: user._id, permission: 'edit' });
    await task.save();
    res.json({ success: true, message: `Đã chỉ định ${user.fullName} làm phụ trách chính`, data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.shareTaskByEmail = async (req, res) => {
  try {
    const { emails, permission } = req.body;
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn không có quyền chia sẻ công việc' });
    const emailList = Array.isArray(emails) ? emails : String(emails || '').split(',');
    let sharedCount = 0;
    for (const raw of emailList) {
      const user = await User.findOne({ email: raw.trim().toLowerCase() });
      if (user && !task.sharedWith.some(s => s.user.toString() === user._id.toString())) { task.sharedWith.push({ user: user._id, permission: permission || 'view' }); sharedCount++; }
    }
    if (sharedCount === 0) return res.status(400).json({ success: false, message: 'Email không tồn tại hoặc đã được chia sẻ' });
    await task.save();
    res.json({ success: true, message: `Đã chia sẻ công việc cho ${sharedCount} người`, data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

// C5 - Xem chi tiết danh sách người phụ trách, người được giao và người được chia sẻ
exports.getTaskParticipants = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id)
      .populate('createdBy', 'fullName email')
      .populate('leadAssignee', 'fullName email')
      .populate('assignees.user', 'fullName email')
      .populate('sharedWith.user', 'fullName email');
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    res.json({
      success: true,
      data: {
        createdBy: task.createdBy,
        leadAssignee: task.leadAssignee,
        assignees: task.assignees,
        sharedWith: task.sharedWith
      }
    });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

// C6 - Thu hồi quyền hoặc gỡ người khỏi công việc
exports.removeTaskParticipant = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) {
      return res.status(403).json({ success: false, message: 'Bạn không có quyền thu hồi hoặc gỡ người' });
    }
    const targetId = req.params.userId;
    task.assignees = task.assignees.filter(a => a.user.toString() !== targetId);
    task.sharedWith = task.sharedWith.filter(s => s.user.toString() !== targetId);
    if (task.leadAssignee && task.leadAssignee.toString() === targetId) {
      task.leadAssignee = null;
    }
    await task.save();
    res.json({ success: true, message: 'Đã thu hồi quyền và gỡ người dùng khỏi công việc', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

// C7 - Kiểm tra danh sách email trước khi xác nhận giao việc cho nhiều người
exports.validateAssignEmails = async (req, res) => {
  try {
    const { emails, permission } = req.body;
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) {
      return res.status(403).json({ success: false, message: 'Bạn không có quyền giao việc' });
    }
    const emailList = Array.isArray(emails) ? emails : String(emails || '').split(',');
    const validUsers = [];
    const invalidEmails = [];
    const seen = new Set();

    for (const raw of emailList) {
      const clean = raw.trim().toLowerCase();
      if (!clean || seen.has(clean)) continue;
      seen.add(clean);
      const user = await User.findOne({ email: clean });
      if (!user) {
        invalidEmails.push(`${clean} (chưa đăng ký)`);
      } else if (task.assignees.some(a => a.user.toString() === user._id.toString())) {
        invalidEmails.push(`${clean} (đã được giao)`);
      } else {
        validUsers.push({ _id: user._id, fullName: user.fullName, email: user.email, permission: permission || 'edit' });
      }
    }

    res.json({
      success: true,
      data: { validUsers, invalidEmails, permission: permission || 'edit' }
    });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
