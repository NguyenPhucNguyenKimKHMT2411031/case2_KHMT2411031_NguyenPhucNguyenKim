const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const taskCrudController = require('../controllers/taskCrudController');

router.post('/', authMiddleware, taskCrudController.createTask);
router.put('/:id', authMiddleware, taskCrudController.updateTask);
router.delete('/:id', authMiddleware, taskCrudController.deleteTask);
router.patch('/:id/status', authMiddleware, taskCrudController.updateStatus);

module.exports = router;