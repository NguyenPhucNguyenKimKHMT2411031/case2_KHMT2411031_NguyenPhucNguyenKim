const express = require('express');
const router = express.Router();
const emailLogController = require('../controllers/emailLogController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.get('/tasks/:taskId/email-logs', verifyToken, emailLogController.getEmailLogsByTask);

module.exports = router;