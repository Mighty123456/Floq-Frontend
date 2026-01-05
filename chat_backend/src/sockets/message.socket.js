module.exports = (io, socket) => {
    socket.on('new message', (newMessageRecieved) => {
        const chat = newMessageRecieved.chat;

        if (!chat || !chat.users) {
            console.log('chat.users not defined');
            return;
        }

        // Emit to all users in the chat except the sender
        chat.users.forEach((user) => {
            if (user._id.toString() === newMessageRecieved.sender._id.toString()) {
                return;
            }
            // Emit to the user's personal room
            socket.in(user._id.toString()).emit('message received', newMessageRecieved);
        });

        // Also emit to the chat room
        socket.in(chat._id.toString()).emit('message received', newMessageRecieved);
    });

    socket.on('message read', async (data) => {
        const { chatId, messageId } = data;
        if (socket.userId) {
            // Notify other users in the chat that message was read
            socket.to(chatId).emit('message read', {
                chatId,
                messageId,
                readBy: socket.userId,
            });
        }
    });
};
