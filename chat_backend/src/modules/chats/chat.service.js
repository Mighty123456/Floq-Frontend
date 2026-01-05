const Chat = require('./chat.model');
const User = require('../users/user.model');

/**
 * Access or create a one-on-one chat
 * @param {ObjectId} currentUserId
 * @param {ObjectId} userId
 * @returns {Promise<Chat>}
 */
const accessChat = async (currentUserId, userId) => {
    let isChat = await Chat.find({
        isGroupChat: false,
        $and: [
            { users: { $elemMatch: { $eq: currentUserId } } },
            { users: { $elemMatch: { $eq: userId } } },
        ],
    })
        .populate('users', '-password')
        .populate('latestMessage');

    isChat = await User.populate(isChat, {
        path: 'latestMessage.sender',
        select: 'name email',
    });

    if (isChat.length > 0) {
        return isChat[0];
    } else {
        const chatData = {
            chatName: 'sender',
            isGroupChat: false,
            users: [currentUserId, userId],
        };

        const createdChat = await Chat.create(chatData);
        const FullChat = await Chat.findOne({ _id: createdChat._id }).populate('users', '-password');
        return FullChat;
    }
};

/**
 * Fetch all chats for a user
 * @param {ObjectId} userId
 * @returns {Promise<Chat[]>}
 */
const fetchChats = async (userId) => {
    let results = await Chat.find({ users: { $elemMatch: { $eq: userId } } })
        .populate('users', '-password')
        .populate('groupAdmin', '-password')
        .populate('latestMessage')
        .sort({ updatedAt: -1 });

    results = await User.populate(results, {
        path: 'latestMessage.sender',
        select: 'name email',
    });

    return results;
};

module.exports = {
    accessChat,
    fetchChats,
};
