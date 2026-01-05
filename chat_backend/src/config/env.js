const dotenv = require('dotenv');
const path = require('path');

// Load .env file
// dotenv loaded via --env-file CLI flag

module.exports = {
    env: process.env.NODE_ENV || 'development',
    port: process.env.PORT ? parseInt(process.env.PORT, 10) : 3000,
    mongoose: {
        url: process.env.MONGODB_URL + (process.env.NODE_ENV === 'test' ? '-test' : ''),
        options: {
            useCreateIndex: true,
            useNewUrlParser: true,
            useUnifiedTopology: true,
        },
    },
    jwt: {
        secret: process.env.JWT_SECRET,
        accessExpirationMinutes: process.env.JWT_ACCESS_EXPIRATION_MINUTES,
        refreshExpirationDays: process.env.JWT_REFRESH_EXPIRATION_DAYS,
    },
    email: {
        smtp: {
            host: process.env.SMTP_HOST,
            port: process.env.SMTP_PORT ? parseInt(process.env.SMTP_PORT, 10) : 587,
            secure: process.env.SMTP_PORT === '465', // true for 465, false for other ports
            auth: {
                user: process.env.SMTP_USERNAME,
                pass: process.env.SMTP_PASSWORD,
            },
            // For Gmail and other services using port 587
            requireTLS: process.env.SMTP_PORT !== '465',
            tls: {
                rejectUnauthorized: false, // Allow self-signed certificates
            },
        },
        from: process.env.EMAIL_FROM,
    },
};
