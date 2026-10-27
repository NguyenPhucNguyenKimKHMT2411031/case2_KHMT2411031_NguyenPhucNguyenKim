const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getTasks, getTaskById } = require('../controllers/taskController');

router.use(auth);
router.get('/', getTasks);
router.get('/:id', getTaskById);

module.exports = router;