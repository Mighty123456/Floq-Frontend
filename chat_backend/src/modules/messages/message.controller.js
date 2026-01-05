const messageService = require('./message.service');

const catchAsync = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((err) => next(err));
};

const sendMessage = catchAsync(async (req, res) => {
    const { content, chatId } = req.body;

    if (!content || !chatId) {
        return res.status(400).send({ message: 'Invalid data passed into request' });
    }

    const message = await messageService.sendMessage(req.user._id, chatId, content);
    res.send(message);
});

const allMessages = catchAsync(async (req, res) => {
    const messages = await messageService.allMessages(req.params.chatId);
    res.send(messages);
});

const markAsRead = catchAsync(async (req, res) => {
    const { chatId } = req.body;
    await messageService.markAsRead(chatId, req.user._id);
    res.send({ message: 'Messages marked as read' });
});

module.exports = {
    sendMessage,
    allMessages,
    markAsRead,
};
