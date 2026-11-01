const express = require('express');
const router = express.Router({ mergeParams: true });
const authMiddleware = require('../middleware/authMiddleware');
const { checkTaskPermission } = require('../middleware/permissionMiddleware');
const assignmentController = require('../controllers/assignmentController');

router.use(authMiddleware);

router.get('/', checkTaskPermission('viewer'), assignmentController.getAssignees);
router.post('/', checkTaskPermission('owner'), assignmentController.assignTask);
router.patch('/:userId', checkTaskPermission('owner'), assignmentController.updatePrimaryAssignee);
router.delete('/:userId', checkTaskPermission('owner'), assignmentController.removeAssignee);

module.exports = router;