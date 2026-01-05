const express = require('express');
const auth = require('../../middlewares/auth.middleware');
const chatController = require('./chat.controller');

const router = express.Router();

router.post('/', auth, chatController.accessChat);
router.get('/', auth, chatController.fetchChats);

module.exports = router;
