const express = require('express');
const router = express.Router({ mergeParams: true });
const authMiddleware = require('../middleware/authMiddleware');
const { checkTaskPermission } = require('../middleware/permissionMiddleware');
const taskShareController = require('../controllers/taskShareController');

router.use(authMiddleware);

router.get('/', checkTaskPermission('viewer'), taskShareController.getShares);
router.post('/', checkTaskPermission('owner'), taskShareController.shareTask);
router.patch('/:shareId', checkTaskPermission('owner'), taskShareController.updateSharePermission);
router.delete('/:shareId', checkTaskPermission('owner'), taskShareController.revokeShare);

module.exports = router;