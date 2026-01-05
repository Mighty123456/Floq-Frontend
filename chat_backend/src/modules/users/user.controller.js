const httpStatus = require('http-status');
const userService = require('./user.service');

const catchAsync = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((err) => next(err));
};

const getUser = catchAsync(async (req, res) => {
    const user = await userService.getUserById(req.params.userId || req.user.id);
    if (!user) {
        res.status(httpStatus.NOT_FOUND).send({ message: 'User not found' });
    }
    res.send(user);
});

const updateUser = catchAsync(async (req, res) => {
    const user = await userService.updateUserById(req.user.id, req.body);
    res.send(user);
});

const searchUsers = catchAsync(async (req, res) => {
    const users = await userService.searchUsers(req.query.q, req.user._id);
    res.send(users);
});

module.exports = {
    getUser,
    updateUser,
    searchUsers,
};
