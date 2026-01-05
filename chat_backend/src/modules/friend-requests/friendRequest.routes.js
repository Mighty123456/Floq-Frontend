const express = require('express');
const auth = require('../../middlewares/auth.middleware');
const friendRequestController = require('./friendRequest.controller');

const router = express.Router();

router.post('/send', auth, friendRequestController.sendFriendRequest);
router.post('/accept', auth, friendRequestController.acceptFriendRequest);
router.post('/decline', auth, friendRequestController.declineFriendRequest);
router.get('/', auth, friendRequestController.getFriendRequests);
router.get('/friends', auth, friendRequestController.getFriends);
router.delete('/remove', auth, friendRequestController.removeFriend);

module.exports = router;

