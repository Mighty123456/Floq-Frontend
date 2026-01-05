const express = require('express');
const authRoute = require('./modules/auth/auth.routes');
const userRoute = require('./modules/users/user.routes');
const chatRoute = require('./modules/chats/chat.routes');
const messageRoute = require('./modules/messages/message.routes');
const groupRoute = require('./modules/groups/group.routes');
const friendRequestRoute = require('./modules/friend-requests/friendRequest.routes');

const router = express.Router();

const defaultRoutes = [
    {
        path: '/auth',
        route: authRoute,
    },
    {
        path: '/users',
        route: userRoute,
    },
    {
        path: '/chats',
        route: chatRoute,
    },
    {
        path: '/messages',
        route: messageRoute,
    },
    {
        path: '/groups',
        route: groupRoute,
    },
    {
        path: '/friend-requests',
        route: friendRequestRoute,
    },
];

defaultRoutes.forEach((route) => {
    router.use(route.path, route.route);
});

module.exports = router;
