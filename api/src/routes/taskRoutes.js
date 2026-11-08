const express = require('express');
const router = express.Router();

// LƯU Ý: Đảm bảo đường dẫn import controller chính xác với dự án của bạn
const taskController = require('../controllers/taskController'); 
// Middleware xác thực JWT Token (nếu có)
const authMiddleware = require('../middlewares/authMiddleware'); 

// Nếu project chưa dùng authMiddleware, bạn có thể tạm thời bỏ authMiddleware khỏi tham số.

// GET /api/tasks - Lấy danh sách công việc
router.get('/', authMiddleware, taskController.getTasks);

// POST /api/tasks - Tạo công việc mới (BẮT BỘC PHẢI CÓ)
router.post('/', authMiddleware, taskController.createTask);

// Chi tiết, Cập nhật, Xóa, Cập nhật trạng thái
router.get('/:id', authMiddleware, taskController.getTaskById);
router.put('/:id', authMiddleware, taskController.updateTask);
router.delete('/:id', authMiddleware, taskController.deleteTask);
router.patch('/:id/status', authMiddleware, taskController.updateTaskStatus);

module.exports = router;