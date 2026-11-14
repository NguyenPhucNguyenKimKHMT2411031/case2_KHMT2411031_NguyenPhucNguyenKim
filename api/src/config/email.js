const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.SMTP_USER, // Khai báo trong .env (VD: your_email@gmail.com)
    pass: process.env.SMTP_PASS, // Mật khẩu ứng dụng (App Password)
  },
});

module.exports = transporter;