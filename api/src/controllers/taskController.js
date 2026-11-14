const Task = require('../models/Task');
const User = require('../models/User');
const Project = require('../models/Project');
const Notification = require('../models/Notification');
const TaskActivity = require('../models/TaskActivity');
const { sendMailNotification } = require('../utils/mailer');

async function logActivity(taskId, actorId, action, detail) {
  try { await TaskActivity.create({ task: taskId, actor: actorId, action, detail }); }
  catch (e) { console.error('[LogActivity Error]:', e.message); }
}

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
    await logActivity(task._id, req.user.id, 'Tạo công việc', `Khởi tạo "${task.title}" (Ưu tiên: ${task.priority})`);
    res.status(201).json({ success: true, message: 'Tạo công việc thành công', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.getTasksByProject = async (req, res) => {
  try {
    const { search, status, priority, sortBy } = req.query;
    const filter = { project: req.params.projectId };
    if (search && search.trim() !== '') filter.title = { $regex: search.trim(),$options: 'i' };
    if (status && status !== 'All') filter.status = status;
    if (priority && priority !== 'All') filter.priority = priority;
    let tasks = await Task.find(filter).populate('leadAssignee', 'fullName email').populate('assignees.user', 'fullName email').populate('sharedWith.user', 'fullName email').sort({ createdAt: -1 });
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
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn chỉ có quyền xem (View)' });
    const oldStatus = task.status;
    task.status = req.body.status;
    await task.save();
    await logActivity(task._id, req.user.id, 'Cập nhật trạng thái', `${oldStatus} -> ${task.status}`);
    res.json({ success: true, message: 'Đã cập nhật trạng thái', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateTaskPriority = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn chỉ có quyền xem (View)' });
    const oldP = task.priority;
    task.priority = req.body.priority;
    await task.save();
    await logActivity(task._id, req.user.id, 'Cập nhật ưu tiên', `${oldP} -> ${task.priority}`);
    res.json({ success: true, message: 'Đã cập nhật ưu tiên', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateTaskDates = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn chỉ có quyền xem (View)' });
    task.startDate = req.body.startDate || null;
    task.dueDate = req.body.dueDate || null;
    await task.save();
    await logActivity(task._id, req.user.id, 'Cập nhật thời gian', 'Thay đổi ngày bắt đầu / hạn chót');
    res.json({ success: true, message: 'Đã cập nhật thời gian', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
exports.assignUsersByEmail = async (req, res) => {
  try {
    const { emails, permission } = req.body;
    const task = await Task.findById(req.params.id).populate('project', 'name');
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn không có quyền giao việc' });
    const assigner = await User.findById(req.user.id);
    const emailList = Array.isArray(emails) ? emails : String(emails || '').split(',');
    const newlyAssigned = [];
    for (const raw of emailList) {
      const user = await User.findOne({ email: raw.trim().toLowerCase() });
      if (user && !task.assignees.some(a => a.user.toString() === user._id.toString())) {
        task.assignees.push({ user: user._id, permission: permission || 'edit' });
        newlyAssigned.push(user);
      }
    }
    if (newlyAssigned.length === 0) return res.status(400).json({ success: false, message: 'Email không hợp lệ hoặc đã được giao' });
    await task.save();
    for (const u of newlyAssigned) {
      await Notification.create({ recipient: u._id, sender: req.user.id, type: 'assign', title: 'Được giao công việc mới', message: `Bạn được giao việc "${task.title}" (quyền: ${permission || 'edit'})`, task: task._id });
      await sendMailNotification({ to: u.email, subject: `[Task Manager] Bạn được giao công việc mới: ${task.title}`, html: `<p><b>${assigner?.fullName || 'Quản lý'}</b> vừa giao cho bạn công việc <b>"${task.title}"</b>.</p>` });
    }
    await logActivity(task._id, req.user.id, 'Giao việc', `Giao cho ${newlyAssigned.map(u => u.fullName).join(', ')} (${permission || 'edit'})`);
    res.json({ success: true, message: `Đã giao việc & gửi email thông báo cho ${newlyAssigned.length} thành viên`, data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.setLeadAssignee = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id).populate('project', 'name');
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn không có quyền chỉ định phụ trách chính' });
    const user = await User.findOne({ email: (req.body.email || '').trim().toLowerCase() });
    if (!user) return res.status(404).json({ success: false, message: 'Không tìm thấy email người dùng' });
    task.leadAssignee = user._id;
    if (!task.assignees.some(a => a.user.toString() === user._id.toString())) task.assignees.push({ user: user._id, permission: 'edit' });
    await task.save();
    await Notification.create({ recipient: user._id, sender: req.user.id, type: 'lead', title: 'Chỉ định phụ trách chính', message: `Bạn là phụ trách chính của "${task.title}"`, task: task._id });
    await logActivity(task._id, req.user.id, 'Phụ trách chính', `Chỉ định ${user.fullName} làm phụ trách chính`);
    res.json({ success: true, message: `Đã chỉ định ${user.fullName} làm phụ trách chính`, data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.shareTaskByEmail = async (req, res) => {
  try {
    const { emails, permission } = req.body;
    const task = await Task.findById(req.params.id).populate('project', 'name');
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn không có quyền chia sẻ' });
    const emailList = Array.isArray(emails) ? emails : String(emails || '').split(',');
    const newlyShared = [];
    for (const raw of emailList) {
      const user = await User.findOne({ email: raw.trim().toLowerCase() });
      if (user && !task.sharedWith.some(s => s.user.toString() === user._id.toString())) {
        task.sharedWith.push({ user: user._id, permission: permission || 'view' });
        newlyShared.push(user);
      }
    }
    if (newlyShared.length === 0) return res.status(400).json({ success: false, message: 'Email không tồn tại hoặc đã được chia sẻ' });
    await task.save();
    const permLabel = (permission || 'view') === 'edit' ? 'Chỉnh sửa (Edit)' : 'Chỉ xem (View)';
    for (const u of newlyShared) {
      await Notification.create({ recipient: u._id, sender: req.user.id, type: 'share', title: 'Công việc được chia sẻ', message: `Bạn được chia sẻ công việc "${task.title}" (${permLabel})`, task: task._id });
    }
    await logActivity(task._id, req.user.id, 'Chia sẻ công việc', `Chia sẻ cho ${newlyShared.map(u => u.fullName).join(', ')} (${permLabel})`);
    res.json({ success: true, message: `Đã chia sẻ công việc cho ${newlyShared.length} người`, data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
exports.getTaskParticipants = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id).populate('createdBy', 'fullName email').populate('leadAssignee', 'fullName email').populate('assignees.user', 'fullName email').populate('sharedWith.user', 'fullName email');
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    res.json({ success: true, data: { createdBy: task.createdBy, leadAssignee: task.leadAssignee, assignees: task.assignees, sharedWith: task.sharedWith } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.removeTaskParticipant = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn không có quyền thu hồi' });
    const targetId = req.params.userId;
    const removedUser = await User.findById(targetId);
    task.assignees = task.assignees.filter(a => a.user.toString() !== targetId);
    task.sharedWith = task.sharedWith.filter(s => s.user.toString() !== targetId);
    if (task.leadAssignee && task.leadAssignee.toString() === targetId) task.leadAssignee = null;
    await task.save();
    await logActivity(task._id, req.user.id, 'Thu hồi quyền', `Gỡ ${removedUser?.fullName || targetId} khỏi công việc`);
    res.json({ success: true, message: 'Đã thu hồi quyền và gỡ người dùng khỏi công việc', data: task });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.validateAssignEmails = async (req, res) => {
  try {
    const { emails, permission } = req.body;
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Không tìm thấy công việc' });
    if (!(await canEditTask(task, req.user.id))) return res.status(403).json({ success: false, message: 'Bạn không có quyền giao việc' });
    const emailList = Array.isArray(emails) ? emails : String(emails || '').split(',');
    const validUsers = [], invalidEmails = [], seen = new Set();
    for (const raw of emailList) {
      const clean = raw.trim().toLowerCase();
      if (!clean || seen.has(clean)) continue;
      seen.add(clean);
      const user = await User.findOne({ email: clean });
      if (!user) invalidEmails.push(`${clean} (chưa đăng ký)`);
      else if (task.assignees.some(a => a.user.toString() === user._id.toString())) invalidEmails.push(`${clean} (đã được giao)`);
      else validUsers.push({ _id: user._id, fullName: user.fullName, email: user.email, permission: permission || 'edit' });
    }
    res.json({ success: true, data: { validUsers, invalidEmails, permission: permission || 'edit' } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.getProjectTaskStats = async (req, res) => {
  try {
    const tasks = await Task.find({ project: req.params.projectId });
    const now = new Date();
    const stats = { total: tasks.length, byStatus: { Todo: 0, 'In-Progress': 0, Done: 0 }, byPriority: { Low: 0, Medium: 0, High: 0 }, overdue: 0 };
    for (const t of tasks) {
      if (stats.byStatus[t.status] !== undefined) stats.byStatus[t.status]++;
      if (stats.byPriority[t.priority] !== undefined) stats.byPriority[t.priority]++;
      if (t.status !== 'Done' && t.dueDate && new Date(t.dueDate) < now) stats.overdue++;
    }
    res.json({ success: true, data: stats });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.getTaskActivities = async (req, res) => {
  try {
    let logs = await TaskActivity.find({ task: req.params.id }).populate('actor', 'fullName email').sort({ createdAt: -1 }).limit(50);
    if (logs.length === 0) {
      const task = await Task.findById(req.params.id);
      if (task) {
        await TaskActivity.create({ task: task._id, actor: task.createdBy || req.user.id, action: 'Tạo công việc', detail: `Khởi tạo "${task.title}" (Trạng thái: ${task.status})` });
        logs = await TaskActivity.find({ task: req.params.id }).populate('actor', 'fullName email').sort({ createdAt: -1 });
      }
    }
    res.json({ success: true, data: logs });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
