const friendRequestService = require('./friendRequest.service');

const catchAsync = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((err) => next(err));
};

const sendFriendRequest = catchAsync(async (req, res) => {
    const { receiverId } = req.body;
    const friendRequest = await friendRequestService.sendFriendRequest(req.user._id, receiverId);
    res.status(201).send(friendRequest);
});

const acceptFriendRequest = catchAsync(async (req, res) => {
    const { requestId } = req.body;
    const result = await friendRequestService.acceptFriendRequest(requestId, req.user._id);
    res.send(result);
});

const declineFriendRequest = catchAsync(async (req, res) => {
    const { requestId } = req.body;
    const friendRequest = await friendRequestService.declineFriendRequest(requestId, req.user._id);
    res.send(friendRequest);
});

const getFriendRequests = catchAsync(async (req, res) => {
    const requests = await friendRequestService.getFriendRequests(req.user._id);
    res.send(requests);
});

const getFriends = catchAsync(async (req, res) => {
    const friends = await friendRequestService.getFriends(req.user._id);
    res.send(friends);
});

const removeFriend = catchAsync(async (req, res) => {
    const { friendId } = req.body;
    await friendRequestService.removeFriend(req.user._id, friendId);
    res.send({ message: 'Friend removed successfully' });
});

module.exports = {
    sendFriendRequest,
    acceptFriendRequest,
    declineFriendRequest,
    getFriendRequests,
    getFriends,
    removeFriend,
};

