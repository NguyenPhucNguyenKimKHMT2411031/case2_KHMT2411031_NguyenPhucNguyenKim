const User = require('../models/User');

// GET /api/users/search?q= - Tìm kiếm người dùng theo tên hoặc email
exports.searchUsers = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) return res.json({ users: [] });

    const users = await User.find({
      $or: [
        { fullName: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } }
      ]
    }).select('fullName email avatarUrl');

    res.json({ users });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi tìm kiếm người dùng', error: err.message });
  }
};