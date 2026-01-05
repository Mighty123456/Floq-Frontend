const chatService = require('./chat.service');

const catchAsync = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((err) => next(err));
};

const accessChat = catchAsync(async (req, res) => {
    const { userId } = req.body;

    if (!userId) {
        return res.status(400).send({ message: 'UserId param not sent with request' });
    }

    const chat = await chatService.accessChat(req.user._id, userId);
    res.send(chat);
});

const fetchChats = catchAsync(async (req, res) => {
    const chats = await chatService.fetchChats(req.user._id);
    res.send(chats);
});

module.exports = {
    accessChat,
    fetchChats,
};
