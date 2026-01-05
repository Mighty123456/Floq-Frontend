const express = require('express');
const auth = require('../../middlewares/auth.middleware');
const groupController = require('./group.controller');

const router = express.Router();

router.post('/', auth, groupController.createGroupChat);
router.put('/rename', auth, groupController.renameGroup);
router.put('/add', auth, groupController.addToGroup);
router.put('/remove', auth, groupController.removeFromGroup);

module.exports = router;
