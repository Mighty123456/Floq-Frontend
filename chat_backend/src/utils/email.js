const nodemailer = require('nodemailer');
const config = require('../config/env');
const logger = require('../config/logger');

// Only create transport if SMTP is configured
let transport = null;
const smtpConfig = config.email && config.email.smtp;
const smtpAuth = smtpConfig && smtpConfig.auth;
if (smtpConfig && smtpConfig.host && smtpAuth && smtpAuth.user && smtpAuth.pass) {
    transport = nodemailer.createTransport(config.email.smtp);
} else {
    logger.warn('SMTP configuration is incomplete. Email functionality will be disabled.');
}

/* istanbul ignore next */
// Verify email connection asynchronously (non-blocking)
if (config.env !== 'test' && transport) {
    // Don't block server startup - verify in background
    transport
        .verify()
        .then(() => {
            logger.info('✓ Connected to email server successfully');
        })
        .catch((error) => {
            const errorMessage = error.message || error.toString();
            if (errorMessage.includes('BadCredentials') || errorMessage.includes('Invalid login')) {
                logger.warn('⚠ Email authentication failed. Email features will be disabled.');
                logger.warn('  To fix this:');
                logger.warn('  1. Enable 2-Step Verification on your Google Account');
                logger.warn('  2. Generate an App Password: https://myaccount.google.com/apppasswords');
                logger.warn('  3. Use the App Password (not your regular password) in SMTP_PASSWORD');
                logger.warn('  4. Make sure SMTP_USERNAME is your full Gmail address');
                // Disable transport so it doesn't keep trying
                transport = null;
            } else {
                logger.warn('⚠ Unable to connect to email server. Email features will be disabled.');
                logger.warn(`  Error: ${errorMessage}`);
                logger.warn('  Check your SMTP configuration in .env file');
                transport = null;
            }
        });
} else if (config.env !== 'test' && !transport) {
    logger.info('ℹ Email service is disabled (SMTP not configured)');
    logger.info('  To enable email: Configure SMTP_HOST, SMTP_USERNAME, and SMTP_PASSWORD in .env');
}

/**
 * Send an email
 * @param {string} to
 * @param {string} subject
 * @param {string} text
 * @returns {Promise}
 */
const sendEmail = async (to, subject, text, html) => {
    if (!transport) {
        logger.warn(`Email sending skipped: Email service is not configured or authentication failed`);
        logger.warn(`  Attempted to send to: ${to}`);
        logger.warn(`  Subject: ${subject}`);
        // In development, you might want to log the OTP instead of throwing
        if (config.env === 'development') {
            logger.info(`  [DEV MODE] Email content: ${text}`);
            return; // Don't throw error in development, just log
        }
        throw new Error('Email service is not available. Please configure SMTP settings in .env');
    }
    const msg = { from: config.email.from, to, subject, text, html };
    await transport.sendMail(msg);
};

/**
 * Send OTP email
 * @param {string} to
 * @param {string} otp
 * @returns {Promise}
 */
const sendOTP = async (to, otp) => {
    const subject = 'Your Verification Code';
    const text = `Your OTP is ${otp}. It expires in 10 minutes.`;
    await sendEmail(to, subject, text);
};

module.exports = {
    transport,
    sendEmail,
    sendOTP,
};
