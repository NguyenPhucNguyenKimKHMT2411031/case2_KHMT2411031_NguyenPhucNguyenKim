const EmailLog = require('../models/EmailLog');

// D3.1: Lấy danh sách email logs theo taskId
exports.getEmailLogsByTask = async (req, res) => {
  try {
    const { taskId } = req.params;
    const logs = await EmailLog.find({ taskId }).sort({ createdAt: -1 });
    return res.status(200).json({ success: true, data: logs });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};