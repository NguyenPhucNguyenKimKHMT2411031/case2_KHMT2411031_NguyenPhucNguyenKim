const Task = require('../models/Task');
const User = require('../models/User');

// E1.1: Thống kê tổng quan công việc (Task Summary Statistics)
exports.getTaskSummary = async (req, res) => {
  try {
    const totalTasks = await Task.countDocuments();
    const completedTasks = await Task.countDocuments({ status: 'completed' });
    const inProgressTasks = await Task.countDocuments({ status: 'in_progress' });
    const pendingTasks = await Task.countDocuments({ status: 'pending' });

    // Đếm số công việc quá hạn
    const now = new Date();
    const overdueTasks = await Task.countDocuments({
      dueDate: { $lt: now },
      status: { $ne: 'completed' },
    });

    return res.status(200).json({
      success: true,
      data: {
        totalTasks,
        completedTasks,
        inProgressTasks,
        pendingTasks,
        overdueTasks,
        completionRate: totalTasks > 0 ? ((completedTasks / totalTasks) * 100).toFixed(2) : 0,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// E1.2: Thống kê hiệu suất theo thành viên (Performance by User)
exports.getUserPerformance = async (req, res) => {
  try {
    const performance = await Task.aggregate([
      {
        $group: {
          _id: '$assignedTo',
          totalAssigned: { $sum: 1 },
          completed: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] },
          },
        },
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'user',
        },
      },
      { $unwind: '$user' },
      {
        $project: {
          _id: 1,
          userName: '$user.name',
          email: '$user.email',
          totalAssigned: 1,
          completed: 1,
          completionRate: {
            $multiply: [{ $divide: ['$completed', '$totalAssigned'] }, 100],
          },
        },
      },
    ]);

    return res.status(200).json({ success: true, data: performance });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};