const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const User = require('../models/User');

// A1 - Đăng ký
exports.register = async (req, res) => {
  try {
    const { fullName, email, password } = req.body;
    if (!fullName || !email || !password) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập đầy đủ họ tên, email và mật khẩu' });
    }
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Email đã được sử dụng' });
    }
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);
    const user = await User.create({ fullName, email, passwordHash });
    res.status(201).json({ success: true, message: 'Đăng ký thành công', data: { id: user._id, fullName: user.fullName, email: user.email } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// A2 - Đăng nhập
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập email và mật khẩu' });
    }
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Email hoặc mật khẩu không đúng' });
    }
    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Email hoặc mật khẩu không đúng' });
    }
    const token = jwt.sign({ id: user._id, email: user.email }, process.env.JWT_SECRET || 'secret123', { expiresIn: '7d' });
    res.json({ success: true, message: 'Đăng nhập thành công', token, user: { id: user._id, fullName: user.fullName, email: user.email, avatarUrl: user.avatarUrl } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// A3 - Xem hồ sơ
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-passwordHash');
    if (!user) return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
    res.json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// A3 - Cập nhật hồ sơ
exports.updateProfile = async (req, res) => {
  try {
    const { fullName, avatarUrl } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { ...(fullName && { fullName }), ...(avatarUrl !== undefined && { avatarUrl }) },
      { new: true }
    ).select('-passwordHash');
    res.json({ success: true, message: 'Cập nhật hồ sơ thành công', data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// A4 - Đổi mật khẩu (khi đã đăng nhập)
exports.changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;
    if (!oldPassword || !newPassword) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập mật khẩu cũ và mật khẩu mới' });
    }
    const user = await User.findById(req.user.id);
    const isMatch = await bcrypt.compare(oldPassword, user.passwordHash);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Mật khẩu hiện tại không đúng' });
    }
    const salt = await bcrypt.genSalt(10);
    user.passwordHash = await bcrypt.hash(newPassword, salt);
    await user.save();
    res.json({ success: true, message: 'Đổi mật khẩu thành công' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// A4 - Quên mật khẩu (Gửi mã OTP 6 số qua Email)
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email: (email || '').toLowerCase() });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Email không tồn tại trong hệ thống' });
    }
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    user.resetOtp = otp;
    user.resetOtpExpires = Date.now() + 10 * 60 * 1000; // Hiệu lực 10 phút
    await user.save();

    console.log(`[OTP RESET PASSWORD] Email: ${user.email} | OTP: ${otp}`);

    if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
      try {
        const transporter = nodemailer.createTransport({
          service: 'gmail',
          auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS }
        });
        await transporter.sendMail({
          from: process.env.EMAIL_USER,
          to: user.email,
          subject: 'Mã OTP đặt lại mật khẩu - Task Manager',
          text: `Mã OTP đặt lại mật khẩu của bạn là: ${otp} (hết hạn sau 10 phút).`
        });
      } catch (mailErr) {
        console.log('Lỗi gửi mail SMTP (vẫn có thể dùng OTP trên console):', mailErr.message);
      }
    }

    res.json({
      success: true,
      message: 'Mã OTP đã được gửi tới email của bạn',
      devOtp: otp
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// A4 - Xác nhận OTP và đặt lại mật khẩu mới
exports.resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    const user = await User.findOne({
      email: (email || '').toLowerCase(),
      resetOtp: otp,
      resetOtpExpires: { $gt: Date.now() }
    });
    if (!user) {
      return res.status(400).json({ success: false, message: 'Mã OTP không đúng hoặc đã hết hạn' });
    }
    const salt = await bcrypt.genSalt(10);
    user.passwordHash = await bcrypt.hash(newPassword, salt);
    user.resetOtp = null;
    user.resetOtpExpires = null;
    await user.save();

    res.json({ success: true, message: 'Đặt lại mật khẩu thành công' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
