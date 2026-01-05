const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const config = require('./config/env');
const logger = require('./config/logger');
const routes = require('./routes');
const { errorConverter, errorHandler } = require('./middlewares/error.middleware');

const app = express();

if (config.env !== 'test') {
    app.use(morgan('combined', { stream: { write: (message) => logger.info(message.trim()) } }));
}

// set security HTTP headers
app.use(helmet());

// parse json request body
app.use(express.json());

// parse urlencoded request body
app.use(express.urlencoded({ extended: true }));

// enable cors
app.use(cors());

// v1 api routes
app.use('/api', routes);

// send back a 404 error for any unknown api request
app.use((req, res, next) => {
    const error = new Error('Not Found');
    error.statusCode = 404;
    next(error);
});

// convert error to ApiError, if needed
app.use(errorConverter);

// handle error
app.use(errorHandler);

module.exports = app;
