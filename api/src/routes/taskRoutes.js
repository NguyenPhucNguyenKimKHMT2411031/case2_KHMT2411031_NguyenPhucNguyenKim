const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getTasks } = require('../controllers/taskController');

router.use(auth);
router.get('/', getTasks);

module.exports = router;