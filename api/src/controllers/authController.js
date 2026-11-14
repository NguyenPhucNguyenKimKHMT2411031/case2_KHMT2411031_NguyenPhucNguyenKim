const bcrypt = require('bcryptjs');
const User = require('../models/User');

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
    res.status(201).json({
      success: true,
      message: 'Đăng ký thành công',
      data: { id: user._id, fullName: user.fullName, email: user.email }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
