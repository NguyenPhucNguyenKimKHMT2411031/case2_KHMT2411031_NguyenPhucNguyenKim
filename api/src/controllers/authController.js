// Ví dụ xử lý tạo Task cơ bản
exports.createTask = async (req, res, next) => {
  try {
    const { title, description, priority, type, status } = req.body;

    if (!title) {
      return res.status(400).json({ message: 'Tiêu đề công việc là bắt buộc' });
    }

    // Giả định tạo task thành công (hoặc lưu qua Mongoose Task.create)
    const newTask = {
      _id: new Date().getTime().toString(),
      title,
      description: description || '',
      priority: priority || 'Medium',
      type: type || 'Personal',
      status: status || 'Pending',
      createdAt: new Date()
    };

    return res.status(201).json(newTask);
  } catch (error) {
    next(error);
  }
};

exports.getTasks = async (req, res, next) => {
  try {
    return res.status(200).json([]);
  } catch (error) {
    next(error);
  }
};

exports.getTaskById = async (req, res, next) => { /* ... */ };
exports.updateTask = async (req, res, next) => { /* ... */ };
exports.deleteTask = async (req, res, next) => { /* ... */ };
exports.updateTaskStatus = async (req, res, next) => { /* ... */ };