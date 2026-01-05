module.exports = (io, socket) => {
    socket.on('typing', (data) => {
        const { chatId, userId } = data;
        if (socket.userId && socket.userId !== userId) {
            // Emit to all users in the chat except the sender
            socket.to(chatId).emit('typing', {
                chatId,
                userId: socket.userId,
                userName: socket.user?.name,
            });
        }
    });

    socket.on('stop typing', (data) => {
        const { chatId, userId } = data;
        if (socket.userId && socket.userId !== userId) {
            socket.to(chatId).emit('stop typing', {
                chatId,
                userId: socket.userId,
            });
        }
    });
};
