const express = require('express');
const router = express.Router();
const projectController = require('../controllers/projectController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);
router.post('/', projectController.createProject);
router.get('/', projectController.getProjects);

module.exports = router;
