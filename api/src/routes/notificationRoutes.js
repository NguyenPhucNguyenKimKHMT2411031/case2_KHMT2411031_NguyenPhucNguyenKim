const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);
router.get('/', notificationController.getMyNotifications);
router.post('/check-deadlines', notificationController.checkDeadlines);
router.patch('/:id/read', notificationController.markAsRead);
router.patch('/read-all', notificationController.markAllAsRead);

module.exports = router;
