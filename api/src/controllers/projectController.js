const Project = require('../models/Project');

exports.createProject = async (req, res) => {
  try {
    const { name, description } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'Vui lòng nhập tên dự án' });
    const project = await Project.create({ name, description: description || '', owner: req.user.id, members: [req.user.id] });
    res.status(201).json({ success: true, message: 'Tạo dự án thành công', data: project });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.getProjects = async (req, res) => {
  try {
    const projects = await Project.find({ $or: [{ owner: req.user.id }, { members: req.user.id }] })
      .populate('owner', 'fullName email avatarUrl').populate('members', 'fullName email avatarUrl').sort({ createdAt: -1 });
    res.json({ success: true, data: projects });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.getProjectById = async (req, res) => {
  try {
    const project = await Project.findById(req.params.id).populate('owner', 'fullName email avatarUrl').populate('members', 'fullName email avatarUrl');
    if (!project) return res.status(404).json({ success: false, message: 'Không tìm thấy dự án' });
    res.json({ success: true, data: project });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.updateProject = async (req, res) => {
  try {
    const { name, description } = req.body;
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ success: false, message: 'Không tìm thấy dự án' });
    if (project.owner.toString() !== req.user.id) return res.status(403).json({ success: false, message: 'Chỉ chủ dự án mới có quyền chỉnh sửa' });
    if (name) project.name = name;
    if (description !== undefined) project.description = description;
    await project.save();
    res.json({ success: true, message: 'Cập nhật dự án thành công', data: project });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.deleteProject = async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ success: false, message: 'Không tìm thấy dự án' });
    if (project.owner.toString() !== req.user.id) return res.status(403).json({ success: false, message: 'Chỉ chủ dự án mới có quyền xóa' });
    await Project.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Đã xóa dự án' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
