const express = require('express');
const auth = require('../../middlewares/auth.middleware');
const userController = require('./user.controller');

const router = express.Router();

router.get('/me', auth, userController.getUser);
router.patch('/me', auth, userController.updateUser);
router.get('/search', auth, userController.searchUsers);
router.get('/:userId', auth, userController.getUser);

module.exports = router;
