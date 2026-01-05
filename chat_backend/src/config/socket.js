const socketIo = require('socket.io');

let io;

const initSocket = (server) => {
    io = socketIo(server, {
        cors: {
            origin: '*', // Allow all origins for now, configure for production later
            methods: ['GET', 'POST'],
        },
    });
    return io;
};

const getIo = () => {
    if (!io) {
        throw new Error('Socket.io not initialized!');
    }
    return io;
};

module.exports = {
    initSocket,
    getIo,
};
