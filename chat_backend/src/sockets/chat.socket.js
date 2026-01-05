const User = require('../modules/users/user.model');
const jwt = require('jsonwebtoken');
const config = require('../config/env');

module.exports = (io, socket) => {
    // Authenticate socket connection
    socket.on('authenticate', async (token) => {
        try {
            const decoded = jwt.verify(token, config.jwt.secret);
            const user = await User.findById(decoded.sub);
            
            if (!user) {
                socket.emit('auth_error', { message: 'User not found' });
                return;
            }

            // Store user info in socket
            socket.userId = user._id.toString();
            socket.user = user;

            // Join user's personal room
            socket.join(user._id.toString());
            
            // Update user online status
            await User.findByIdAndUpdate(user._id, { 
                isOnline: true,
                lastSeen: new Date()
            });

            // Notify friends that user is online
            socket.broadcast.emit('user_online', { userId: user._id.toString() });

            socket.emit('authenticated', { userId: user._id.toString() });
            console.log(`User ${user.name} (${user._id}) connected`);
        } catch (error) {
            socket.emit('auth_error', { message: 'Authentication failed' });
        }
    });

    socket.on('setup', (userData) => {
        if (socket.userId) {
            socket.join(socket.userId);
            socket.emit('connected');
        }
    });

    socket.on('join chat', (room) => {
        socket.join(room);
        console.log(`User ${socket.userId} Joined Room: ${room}`);
    });

    socket.on('leave chat', (room) => {
        socket.leave(room);
        console.log(`User ${socket.userId} Left Room: ${room}`);
    });

    // Handle disconnect
    socket.on('disconnect', async () => {
        if (socket.userId) {
            // Update user offline status
            await User.findByIdAndUpdate(socket.userId, { 
                isOnline: false,
                lastSeen: new Date()
            });

            // Notify friends that user is offline
            socket.broadcast.emit('user_offline', { userId: socket.userId });
            console.log(`User ${socket.userId} disconnected`);
        }
    });
};
