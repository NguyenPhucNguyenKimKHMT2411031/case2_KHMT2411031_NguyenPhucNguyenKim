const Project = require('../models/Project');

// B1 - Tạo dự án mới
exports.createProject = async (req, res) => {
  try {
    const { name, description } = req.body;
    if (!name) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập tên dự án' });
    }
    const project = await Project.create({
      name,
      description: description || '',
      owner: req.user.id,
      members: [req.user.id]
    });
    res.status(201).json({ success: true, message: 'Tạo dự án thành công', data: project });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// B1 - Lấy danh sách dự án của người dùng (làm chủ hoặc là thành viên)
exports.getProjects = async (req, res) => {
  try {
    const projects = await Project.find({
      $or: [{ owner: req.user.id }, { members: req.user.id }]
    })
      .populate('owner', 'fullName email avatarUrl')
      .populate('members', 'fullName email avatarUrl')
      .sort({ createdAt: -1 });

    res.json({ success: true, data: projects });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
