const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { fullName, email, password } = req.body;
    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ message: 'Email đã tồn tại' });

    const passwordHash = await bcrypt.hash(password, 10);
    const user = new User({ fullName, email, passwordHash });
    await user.save();

    res.status(201).json({ message: 'Đăng ký thành công', userId: user._id });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi đăng ký', error: err.message });
  }
};

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Email hoặc mật khẩu không đúng' });

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) return res.status(400).json({ message: 'Email hoặc mật khẩu không đúng' });

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    res.json({ message: 'Đăng nhập thành công', token, user: { id: user._id, fullName: user.fullName, email: user.email } });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi đăng nhập', error: err.message });
  }
};

// GET /api/auth/me
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-passwordHash');
    res.json({ user });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi lấy thông tin', error: err.message });
  }
};

// PUT /api/auth/me - Cập nhật thông tin cá nhân (Chức năng 1 - Phần A)
exports.updateMe = async (req, res) => {
  try {
    const { fullName, avatarUrl } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { fullName, avatarUrl },
      { new: true, runValidators: true }
    ).select('-passwordHash');

    res.json({ message: 'Cập nhật thông tin cá nhân thành công', user });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi cập nhật thông tin', error: err.message });
  }
};