const router = require('express').Router();
const authModule = require('../middleware/authMiddleware');
// Tự nhận cách xuất của authMiddleware.js (export mặc định hoặc export tên)
const authMiddleware =
  typeof authModule === 'function'
    ? authModule
    : authModule.authMiddleware ||
      authModule.protect ||
      authModule.verifyToken ||
      Object.values(authModule).find((v) => typeof v === 'function');
const crud = require('../controllers/taskCrudController');

router.use(authMiddleware);

router.post('/', crud.createTask);

module.exports = router;