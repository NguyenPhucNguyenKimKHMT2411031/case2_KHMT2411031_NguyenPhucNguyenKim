const EmailLog = require('../models/EmailLog');
const transporter = require('../config/email');

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

// D3.2: Thử gửi lại email thất bại (Retry)
exports.retryEmailLog = async (req, res) => {
  try {
    const { logId } = req.params;
    const log = await EmailLog.findById(logId);

    if (!log) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy nhật ký email' });
    }

    log.attempts += 1;

    try {
      await transporter.sendMail({
        from: `"Task Manager" <${process.env.SMTP_USER}>`,
        to: log.recipientEmail,
        subject: log.subject,
        text: `[RETRY #${log.attempts}] Thông báo lại cho công việc.`,
      });

      log.status = 'sent';
      log.sentAt = new Date();
      log.errorMessage = null;
      await log.save();

      return res.status(200).json({ success: true, message: 'Gửi lại email thành công', data: log });
    } catch (sendError) {
      log.status = 'failed';
      log.errorMessage = sendError.message;
      await log.save();

      return res.status(500).json({ success: false, message: `Thử lại thất bại: ${sendError.message}` });
    }
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};