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
        completionRate: totalTasks > 0 ? Number(((completedTasks / totalTasks) * 100).toFixed(2)) : 0,
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
          _id: '$primaryAssignee',
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
          userName: '$user.fullName',
          email: '$user.email',
          totalAssigned: 1,
          completed: 1,
          completionRate: {
            $cond: [
              { $gt: ['$totalAssigned', 0] },
              { $multiply: [{ $divide: ['$completed', '$totalAssigned'] }, 100] },
              0
            ]
          },
        },
      },
    ]);

    return res.status(200).json({ success: true, data: performance });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// E1.3: Thống kê công việc được giao & đang phụ trách của User hiện tại
exports.getMyTaskStatistics = async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;

    // Công việc tôi phụ trách chính
    const primaryTasks = await Task.countDocuments({ primaryAssignee: userId });

    // Công việc tôi được giao (nằm trong mảng assignees)
    const assignedTasks = await Task.countDocuments({ assignees: userId });

    // Công việc do tôi khởi tạo
    const createdTasks = await Task.countDocuments({ createdBy: userId });

    return res.status(200).json({
      success: true,
      data: {
        primaryTasks,
        assignedTasks,
        createdTasks,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
// E2: Hiển thị công việc sắp đến hạn và đã quá hạn
exports.getUpcomingAndOverdueTasks = async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const now = new Date();
    const next48Hours = new Date(now.getTime() + 48 * 60 * 60 * 1000);

    // Công việc đã quá hạn (chưa completed)
    const overdueTasks = await Task.find({
      $or: [{ primaryAssignee: userId }, { assignees: userId }],
      dueDate: { $lt: now },
      status: { $ne: 'completed' },
    }).sort({ dueDate: 1 });

    // Công việc sắp đến hạn (trong vòng 48h tới, chưa completed)
    const upcomingTasks = await Task.find({
      $or: [{ primaryAssignee: userId }, { assignees: userId }],
      dueDate: { $gte: now, $lte: next48Hours },
      status: { $ne: 'completed' },
    }).sort({ dueDate: 1 });

    return res.status(200).json({
      success: true,
      data: {
        overdue: overdueTasks,
        upcoming: upcomingTasks,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
// E3: Lấy nhật ký hoạt động của công việc (Task Activity Logs)
exports.getTaskActivityLogs = async (req, res) => {
  try {
    const { taskId } = req.params;
    
    // Tìm danh sách lịch sử thao tác của công việc (sắp xếp mới nhất lên đầu)
    const logs = await ActivityLog.find({ task: taskId })
      .populate('user', 'fullName email')
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: logs,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};