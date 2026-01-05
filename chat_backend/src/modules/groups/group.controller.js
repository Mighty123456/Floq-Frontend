const groupService = require('./group.service');

const catchAsync = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((err) => next(err));
};

const createGroupChat = catchAsync(async (req, res) => {
    if (!req.body.users || !req.body.name) {
        return res.status(400).send({ message: 'Please fill all the fields' });
    }

    let users = JSON.parse(req.body.users);

    const groupChat = await groupService.createGroupChat(req.body.name, users, req.user._id);
    res.status(200).send(groupChat);
});

const renameGroup = catchAsync(async (req, res) => {
    const { chatId, chatName } = req.body;
    const updatedChat = await groupService.renameGroup(chatId, chatName);
    res.send(updatedChat);
});

const addToGroup = catchAsync(async (req, res) => {
    const { chatId, userId } = req.body;
    const added = await groupService.addToGroup(chatId, userId);
    res.send(added);
});

const removeFromGroup = catchAsync(async (req, res) => {
    const { chatId, userId } = req.body;
    const removed = await groupService.removeFromGroup(chatId, userId);
    res.send(removed);
});

module.exports = {
    createGroupChat,
    renameGroup,
    addToGroup,
    removeFromGroup,
};
