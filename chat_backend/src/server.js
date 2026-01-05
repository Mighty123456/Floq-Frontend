const app = require('./app');
const http = require('http');
const config = require('./config/env');
const logger = require('./config/logger');
const connectDB = require('./config/db');
const { initSocket } = require('./config/socket');
const socketHandler = require('./sockets');

let server;

// Connect to MongoDB
connectDB()
    .then(() => {
        logger.info('Connected to MongoDB');

        const httpServer = http.createServer(app);

        // Initialize Socket.IO
        const io = initSocket(httpServer);

        // Initialize Socket Handlers
        socketHandler(io);

        server = httpServer.listen(config.port, () => {
            logger.info(`Listening to port ${config.port}`);
        });

        // Handle server errors
        httpServer.on('error', (error) => {
            if (error.code === 'EADDRINUSE') {
                logger.error(`Port ${config.port} is already in use. Please use a different port.`);
            } else {
                logger.error('Server error:', error);
            }
            process.exit(1);
        });
    })
    .catch((error) => {
        logger.error('Failed to start server:', error);
        process.exit(1);
    });

const exitHandler = () => {
    if (server) {
        server.close(() => {
            logger.info('Server closed');
            process.exit(1);
        });
    } else {
        process.exit(1);
    }
};

const unexpectedErrorHandler = (error) => {
    logger.error(error);
    exitHandler();
};

process.on('uncaughtException', unexpectedErrorHandler);
process.on('unhandledRejection', unexpectedErrorHandler);

process.on('SIGTERM', () => {
    logger.info('SIGTERM received');
    if (server) {
        server.close();
    }
});
