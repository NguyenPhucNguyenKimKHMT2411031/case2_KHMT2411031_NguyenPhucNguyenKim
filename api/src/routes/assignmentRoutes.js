const express = require('express');
const router = express.Router({ mergeParams: true });
const assignmentController = require('../controllers/assignmentController');
const authMiddleware = require('../middleware/authMiddleware');

// GET /api/tasks/:id/assignees - Xem danh sách người được giao
router.get('/', authMiddleware, assignmentController.getAssignees);

// POST /api/tasks/:id/assignees - Giao việc cho 1 hoặc nhiều người
router.post('/', authMiddleware, assignmentController.assignTask);

module.exports = router;