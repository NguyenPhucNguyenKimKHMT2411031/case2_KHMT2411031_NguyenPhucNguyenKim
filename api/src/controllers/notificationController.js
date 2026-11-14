const Notification = require('../models/Notification');
const Task = require('../models/Task');
const User = require('../models/User');
const { sendMailNotification } = require('../utils/mailer');

exports.getMyNotifications = async (req, res) => {
  try {
    const list = await Notification.find({ recipient: req.user.id })
      .populate('sender', 'fullName email')
      .sort({ createdAt: -1 })
      .limit(50);
    const unreadCount = list.filter(n => !n.isRead).length;
    res.json({ success: true, data: list, unreadCount });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.markAsRead = async (req, res) => {
  try {
    await Notification.findOneAndUpdate({ _id: req.params.id, recipient: req.user.id }, { isRead: true });
    res.json({ success: true, message: 'Đã đánh dấu đã đọc' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany({ recipient: req.user.id, isRead: false }, { isRead: true });
    res.json({ success: true, message: 'Đã đánh dấu tất cả là đã đọc' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

// D4 - Quét và gửi nhắc hạn công việc sắp đến hạn (<= 24h) và quá hạn
exports.checkDeadlines = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);
    const now = new Date();
    const in24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    const tasks = await Task.find({
      status: { $ne: 'Done' },
      dueDate: { $ne: null, $lte: in24h },
      $or: [
        { createdBy: userId },
        { leadAssignee: userId },
        { 'assignees.user': userId }
      ]
    }).populate('project', 'name');

    let createdCount = 0;
    const alerts = [];

    for (const t of tasks) {
      const due = new Date(t.dueDate);
      const isOverdue = due < now;
      const statusLabel = isOverdue ? 'QUÁ HẠN' : 'SẮP ĐẾN HẠN';
      const title = `[${statusLabel}] Công việc: ${t.title}`;
      const message = `Dự án "${t.project?.name || ''}" • Hạn chót: ${due.toLocaleDateString('vi-VN')}`;

      alerts.push({ taskId: t._id, title: t.title, isOverdue, dueDate: t.dueDate });

      // Tránh spam trùng thông báo nhắc hạn cho cùng 1 task trong cùng 1 ngày
      const existedToday = await Notification.findOne({
        recipient: userId,
        task: t._id,
        type: 'deadline',
        createdAt: { $gte: startOfDay }
      });

      if (!existedToday) {
        await Notification.create({
          recipient: userId,
          type: 'deadline',
          title,
          message,
          task: t._id
        });
        createdCount++;

        if (user && user.email) {
          await sendMailNotification({
            to: user.email,
            subject: `[Task Manager] ${title}`,
            html: `<p>Xin chào <b>${user.fullName}</b>,</p>
                   <p>Công việc <b>"${t.title}"</b> (Dự án: <b>${t.project?.name || ''}</b>) hiện đang <b style="color:${isOverdue ? 'red' : 'orange'}">${statusLabel}</b>.</p>
                   <p>Hạn hoàn thành: <b>${due.toLocaleDateString('vi-VN')}</b></p>`
          });
        }
      }
    }

    res.json({
      success: true,
      message: `Tìm thấy ${alerts.length} việc cần lưu ý (tạo mới ${createdCount} nhắc hạn)`,
      data: alerts
    });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
