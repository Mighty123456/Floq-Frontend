module.exports = (io) => {
    io.on('connection', (socket) => {
        console.log('New client connected', socket.id);

        socket.on('disconnect', () => {
            console.log('Client disconnected', socket.id);
        });

        // Import other socket handlers here and pass socket/io
        require('./chat.socket')(io, socket);
        require('./message.socket')(io, socket);
        require('./typing.socket')(io, socket);
    });
};
