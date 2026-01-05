const Chat = require('../chats/chat.model');

/**
 * Create a group chat
 * @param {string} chatName
 * @param {Array<ObjectId>} users
 * @param {ObjectId} adminId
 * @returns {Promise<Chat>}
 */
const createGroupChat = async (chatName, users, adminId) => {
    if (users.length < 2) {
        throw new Error('More than 2 users are required to form a group chat');
    }

    users.push(adminId);

    const groupChat = await Chat.create({
        chatName: chatName,
        users: users,
        isGroupChat: true,
        groupAdmin: adminId,
    });

    const fullGroupChat = await Chat.findOne({ _id: groupChat._id })
        .populate('users', '-password')
        .populate('groupAdmin', '-password');

    return fullGroupChat;
};

/**
 * Rename group
 * @param {ObjectId} chatId
 * @param {string} chatName
 * @returns {Promise<Chat>}
 */
const renameGroup = async (chatId, chatName) => {
    const updatedChat = await Chat.findByIdAndUpdate(
        chatId,
        { chatName: chatName },
        { new: true }
    )
        .populate('users', '-password')
        .populate('groupAdmin', '-password');

    if (!updatedChat) {
        throw new Error('Chat Not Found');
    }
    return updatedChat;
};

/**
 * Add user to group
 * @param {ObjectId} chatId
 * @param {ObjectId} userId
 * @returns {Promise<Chat>}
 */
const addToGroup = async (chatId, userId) => {
    const added = await Chat.findByIdAndUpdate(
        chatId,
        { $push: { users: userId } },
        { new: true }
    )
        .populate('users', '-password')
        .populate('groupAdmin', '-password');

    if (!added) {
        throw new Error('Chat Not Found');
    }
    return added;
};

/**
 * Remove user from group
 * @param {ObjectId} chatId
 * @param {ObjectId} userId
 * @returns {Promise<Chat>}
 */
const removeFromGroup = async (chatId, userId) => {
    const removed = await Chat.findByIdAndUpdate(
        chatId,
        { $pull: { users: userId } },
        { new: true }
    )
        .populate('users', '-password')
        .populate('groupAdmin', '-password');

    if (!removed) {
        throw new Error('Chat Not Found');
    }
    return removed;
};

module.exports = {
    createGroupChat,
    renameGroup,
    addToGroup,
    removeFromGroup,
};
