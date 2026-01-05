const config = require('../config/env');
const logger = require('../config/logger');

const errorConverter = (err, req, res, next) => {
    let error = err;
    if (!(error instanceof Error)) {
        error = new Error(error.message || 'Unknown Error');
        error.statusCode = error.statusCode || 500;
    }
    next(error);
};

const errorHandler = (err, req, res, next) => {
    let { statusCode, message } = err;
    if (!statusCode) statusCode = 500;

    const response = {
        code: statusCode,
        message,
        ...(config.env === 'development' && { stack: err.stack }),
    };

    if (config.env === 'development') {
        logger.error(err);
    }

    res.status(statusCode).send(response);
};

module.exports = {
    errorConverter,
    errorHandler,
};
