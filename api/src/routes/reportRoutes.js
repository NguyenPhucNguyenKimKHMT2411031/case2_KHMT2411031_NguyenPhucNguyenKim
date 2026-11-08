const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.get('/reports/summary', verifyToken, reportController.getTaskSummary);
router.get('/reports/user-performance', verifyToken, reportController.getUserPerformance);

module.exports = router;