const nodemailer = require('nodemailer');

let cachedTransporter = null;

async function getTransporter() {
  if (cachedTransporter) return cachedTransporter;
  if (process.env.SMTP_USER && process.env.SMTP_PASS) {
    cachedTransporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
    });
  } else {
    const testAccount = await nodemailer.createTestAccount();
    cachedTransporter = nodemailer.createTransport({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false,
      auth: { user: testAccount.user, pass: testAccount.pass }
    });
    console.log('[Mailer] Đang dùng hộp thư test Ethereal:', testAccount.user);
  }
  return cachedTransporter;
}

exports.sendMailNotification = async ({ to, subject, html }) => {
  try {
    const transporter = await getTransporter();
    const info = await transporter.sendMail({
      from: `"Task Manager" <${process.env.SMTP_USER || 'no-reply@taskmanager.local'}>`,
      to,
      subject,
      html
    });
    const previewUrl = nodemailer.getTestMessageUrl(info);
    if (previewUrl) {
      console.log(`[Email Preview -> ${to}]: ${previewUrl}`);
    } else {
      console.log(`[Email Sent -> ${to}]: ${info.messageId}`);
    }
    return { sent: true, previewUrl: previewUrl || null };
  } catch (err) {
    console.error('[Mailer Error]:', err.message);
    return { sent: false, error: err.message };
  }
};
