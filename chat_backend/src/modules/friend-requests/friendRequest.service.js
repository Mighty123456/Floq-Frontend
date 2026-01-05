const FriendRequest = require('./friendRequest.model');
const User = require('../users/user.model');
const Chat = require('../chats/chat.model');

/**
 * Send a friend request
 * @param {ObjectId} senderId
 * @param {ObjectId} receiverId
 * @returns {Promise<FriendRequest>}
 */
const sendFriendRequest = async (senderId, receiverId) => {
    if (senderId.toString() === receiverId.toString()) {
        throw new Error('Cannot send friend request to yourself');
    }

    // Check if request already exists
    const existingRequest = await FriendRequest.findOne({
        $or: [
            { sender: senderId, receiver: receiverId },
            { sender: receiverId, receiver: senderId },
        ],
    });

    if (existingRequest) {
        if (existingRequest.status === 'pending') {
            throw new Error('Friend request already sent');
        }
        if (existingRequest.status === 'accepted') {
            throw new Error('Already friends');
        }
    }

    const friendRequest = await FriendRequest.create({
        sender: senderId,
        receiver: receiverId,
        status: 'pending',
    });

    return await friendRequest.populate('sender receiver', 'name email profilePicture');
};

/**
 * Accept a friend request
 * @param {ObjectId} requestId
 * @param {ObjectId} userId
 * @returns {Promise<{friendRequest: FriendRequest, chat: Chat}>}
 */
const acceptFriendRequest = async (requestId, userId) => {
    const friendRequest = await FriendRequest.findById(requestId);

    if (!friendRequest) {
        throw new Error('Friend request not found');
    }

    if (friendRequest.receiver.toString() !== userId.toString()) {
        throw new Error('Unauthorized to accept this request');
    }

    if (friendRequest.status !== 'pending') {
        throw new Error('Friend request already processed');
    }

    friendRequest.status = 'accepted';
    await friendRequest.save();

    // Create a chat between the two users
    let chat = await Chat.findOne({
        isGroupChat: false,
        $and: [
            { users: { $elemMatch: { $eq: friendRequest.sender } } },
            { users: { $elemMatch: { $eq: friendRequest.receiver } } },
        ],
    });

    if (!chat) {
        chat = await Chat.create({
            chatName: 'sender',
            isGroupChat: false,
            users: [friendRequest.sender, friendRequest.receiver],
        });
    }

    const populatedRequest = await friendRequest.populate('sender receiver', 'name email profilePicture');
    const populatedChat = await Chat.findById(chat._id).populate('users', '-password');

    return { friendRequest: populatedRequest, chat: populatedChat };
};

/**
 * Decline a friend request
 * @param {ObjectId} requestId
 * @param {ObjectId} userId
 * @returns {Promise<FriendRequest>}
 */
const declineFriendRequest = async (requestId, userId) => {
    const friendRequest = await FriendRequest.findById(requestId);

    if (!friendRequest) {
        throw new Error('Friend request not found');
    }

    if (friendRequest.receiver.toString() !== userId.toString()) {
        throw new Error('Unauthorized to decline this request');
    }

    friendRequest.status = 'declined';
    await friendRequest.save();

    return await friendRequest.populate('sender receiver', 'name email profilePicture');
};

/**
 * Get all friend requests for a user
 * @param {ObjectId} userId
 * @returns {Promise<{sent: FriendRequest[], received: FriendRequest[]}>}
 */
const getFriendRequests = async (userId) => {
    const sent = await FriendRequest.find({ sender: userId, status: 'pending' })
        .populate('receiver', 'name email profilePicture')
        .sort({ createdAt: -1 });

    const received = await FriendRequest.find({ receiver: userId, status: 'pending' })
        .populate('sender', 'name email profilePicture')
        .sort({ createdAt: -1 });

    return { sent, received };
};

/**
 * Get all friends (accepted requests)
 * @param {ObjectId} userId
 * @returns {Promise<User[]>}
 */
const getFriends = async (userId) => {
    const friendRequests = await FriendRequest.find({
        status: 'accepted',
        $or: [{ sender: userId }, { receiver: userId }],
    })
        .populate('sender receiver', 'name email profilePicture isOnline lastSeen')
        .lean();

    const friends = friendRequests.map((fr) => {
        const friend = fr.sender._id.toString() === userId.toString() ? fr.receiver : fr.sender;
        return friend;
    });

    return friends;
};

/**
 * Remove friend (delete friend request and chat)
 * @param {ObjectId} userId
 * @param {ObjectId} friendId
 * @returns {Promise<void>}
 */
const removeFriend = async (userId, friendId) => {
    await FriendRequest.deleteOne({
        status: 'accepted',
        $or: [
            { sender: userId, receiver: friendId },
            { sender: friendId, receiver: userId },
        ],
    });

    // Optionally delete the chat as well
    await Chat.deleteOne({
        isGroupChat: false,
        $and: [
            { users: { $elemMatch: { $eq: userId } } },
            { users: { $elemMatch: { $eq: friendId } } },
        ],
    });
};

module.exports = {
    sendFriendRequest,
    acceptFriendRequest,
    declineFriendRequest,
    getFriendRequests,
    getFriends,
    removeFriend,
};

