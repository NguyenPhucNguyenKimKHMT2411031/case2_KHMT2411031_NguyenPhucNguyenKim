const bcrypt = require('bcryptjs');
const User = require('../models/User');

exports.register = async (req, res, next) => {
  try {
    const { fullName, email, password } = req.body;
    if (!fullName || !email || !password || password.length < 6) {
      return res.status(400).json({ message: 'Dữ liệu không hợp lệ' });
    }
    const exists = await User.findOne({ email: email.toLowerCase() });
    if (exists) return res.status(409).json({ message: 'Email đã được sử dụng' });

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ fullName, email, passwordHash });
    res.status(201).json({ id: user._id, fullName: user.fullName, email: user.email });
  } catch (e) {
    next(e);
  }
};