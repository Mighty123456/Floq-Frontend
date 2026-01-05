const express = require('express');
const auth = require('../../middlewares/auth.middleware');
const messageController = require('./message.controller');

const router = express.Router();

router.post('/', auth, messageController.sendMessage);
router.post('/read', auth, messageController.markAsRead);
router.get('/:chatId', auth, messageController.allMessages);

module.exports = router;
