const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const authMiddleware = require('../middleware/authMiddleware');

// D1.1: Lấy danh sách thông báo
router.get('/', authMiddleware, notificationController.getNotifications);

// D1.2: Đánh dấu 1 thông báo đã đọc
router.patch('/:id/read', authMiddleware, notificationController.markAsRead);

module.exports = router;