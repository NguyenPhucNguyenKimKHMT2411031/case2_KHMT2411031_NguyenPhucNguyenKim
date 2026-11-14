const TaskShare = require('../models/TaskShare');

// GET /api/tasks/:id/shares - Lấy danh sách người được chia sẻ
exports.getShares = async (req, res) => {
  try {
    const shares = await TaskShare.find({ taskId: req.params.id }).populate('userId', 'fullName email avatarUrl');
    res.json({ shares });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi lấy danh sách chia sẻ', error: err.message });
  }
};

// POST /api/tasks/:id/shares - Chia sẻ công việc cho 1 hoặc nhiều người (Chỉ Owner)
exports.shareTask = async (req, res) => {
  try {
    const { userIds, permission } = req.body; // permission: 'viewer' hoặc 'editor'
    const taskId = req.params.id;
    const sharedBy = req.user._id;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({ message: 'Vui lòng cung cấp danh sách người dùng' });
    }

    const sharePromises = userIds.map(userId =>
      TaskShare.findOneAndUpdate(
        { taskId, userId },
        { permission: permission || 'viewer', sharedBy },
        { upsert: true, new: true }
      )
    );
    await Promise.all(sharePromises);
    res.json({ message: 'Chia sẻ công việc thành công' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi chia sẻ công việc', error: err.message });
  }
};

// PATCH /api/tasks/:id/shares/:shareId - Thay đổi quyền viewer/editor (Chỉ Owner)
exports.updateSharePermission = async (req, res) => {
  try {
    const { permission } = req.body;
    if (!['viewer', 'editor'].includes(permission)) {
      return res.status(400).json({ message: 'Quyền không hợp lệ (chỉ nhận viewer hoặc editor)' });
    }
    const share = await TaskShare.findByIdAndUpdate(req.params.shareId, { permission }, { new: true });
    res.json({ message: 'Cập nhật quyền chia sẻ thành công', share });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi cập nhật quyền chia sẻ', error: err.message });
  }
};

// DELETE /api/tasks/:id/shares/:shareId - Thu hồi quyền chia sẻ (Chỉ Owner)
exports.revokeShare = async (req, res) => {
  try {
    await TaskShare.findByIdAndDelete(req.params.shareId);
    res.json({ message: 'Thu hồi quyền chia sẻ thành công' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi thu hồi quyền chia sẻ', error: err.message });
  }
};