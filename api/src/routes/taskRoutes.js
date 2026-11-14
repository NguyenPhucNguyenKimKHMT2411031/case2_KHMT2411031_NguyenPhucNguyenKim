const express = require('express');
const router = express.Router();
const taskController = require('../controllers/taskController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);
router.post('/', taskController.createTask);
router.get('/project/:projectId', taskController.getTasksByProject);
router.patch('/:id/status', taskController.updateTaskStatus);
router.patch('/:id/priority', taskController.updateTaskPriority);

module.exports = router;
