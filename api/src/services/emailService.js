const transporter = require('../config/email');
const EmailLog = require('../models/EmailLog');

/**
 * Hàm gửi Email thông báo và tự động ghi log vào MongoDB (Collection email_logs)
 */
const sendNotificationEmail = async ({ taskId, recipientEmail, eventType, subject, textContent }) => {
  let emailLog;
  try {
    // 1. Tạo bản ghi Log ban đầu với trạng thái pending
    emailLog = await EmailLog.create({
      taskId: taskId || null,
      recipientEmail,
      eventType, // VD: 'ASSIGN_TASK', 'SHARE_TASK'
      subject,
      status: 'pending',
      attempts: 1,
    });

    // 2. Gửi Email qua transporter
    await transporter.sendMail({
      from: `"Task Manager" <${process.env.SMTP_USER}>`,
      to: recipientEmail,
      subject: subject,
      text: textContent,
    });

    // 3. Cập nhật trạng thái thành công (sent)
    emailLog.status = 'sent';
    emailLog.sentAt = new Date();
    await emailLog.save();
    return { success: true };
  } catch (error) {
    // 4. Cập nhật trạng thái thất bại (failed) và lưu thông báo lỗi
    if (emailLog) {
      emailLog.status = 'failed';
      emailLog.errorMessage = error.message;
      await emailLog.save();
    }
    console.error('Lỗi gửi email:', error.message);
    return { success: false, error: error.message };
  }
};

module.exports = { sendNotificationEmail };