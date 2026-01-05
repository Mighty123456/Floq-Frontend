const mongoose = require('mongoose');
const config = require('./env');
const logger = require('./logger');

const connectDB = async () => {
    try {
        await mongoose.connect(config.mongoose.url);
        logger.info('Connected to MongoDB');
    } catch (error) {
        logger.error('Could not connect to MongoDB', error);
        process.exit(1);
    }
};

module.exports = connectDB;
