const Notification = require('../models/Notification');

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
