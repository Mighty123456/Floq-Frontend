const Message = require('./message.model');
const User = require('../users/user.model');
const Chat = require('../chats/chat.model');

/**
 * Send a message
 * @param {ObjectId} senderId
 * @param {ObjectId} chatId
 * @param {string} content
 * @returns {Promise<Message>}
 */
const sendMessage = async (senderId, chatId, content) => {
    const newMessage = {
        sender: senderId,
        content: content,
        chat: chatId,
    };

    let message = await Message.create(newMessage);

    message = await message.populate('sender', 'name pic'); // pic not implemented yet but generic
    message = await message.populate('chat');
    message = await User.populate(message, {
        path: 'chat.users',
        select: 'name email',
    });

    await Chat.findByIdAndUpdate(chatId, {
        latestMessage: message,
    });

    return message;
};

/**
 * Get all messages for a chat
 * @param {ObjectId} chatId
 * @returns {Promise<Message[]>}
 */
const allMessages = async (chatId) => {
    const messages = await Message.find({ chat: chatId })
        .populate('sender', 'name email profilePicture')
        .populate('chat')
        .populate('readBy', 'name email')
        .sort({ createdAt: 1 });

    return messages;
};

/**
 * Mark messages as read
 * @param {ObjectId} chatId
 * @param {ObjectId} userId
 * @returns {Promise<Message[]>}
 */
const markAsRead = async (chatId, userId) => {
    const messages = await Message.updateMany(
        {
            chat: chatId,
            sender: { $ne: userId },
            readBy: { $ne: userId },
        },
        {
            $addToSet: { readBy: userId },
        }
    );

    return messages;
};

module.exports = {
    sendMessage,
    allMessages,
    markAsRead,
};
