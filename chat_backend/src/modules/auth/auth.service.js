const httpStatus = require('http-status'); // Need to install this or use numbers
// Using explicit numbers if http-status not installed: 400, 401, 404, etc.
// But best practice to return errors. I'll define a simple ApiError class or just throw errors.
// Wait, I haven't implemented ApiError class properly (it was referred in middleware).
// I will create utils/ApiError.js first or just use Error.
// I'll proceed assuming ApiError exists or just throw standard Errors with status.

// Let's create ApiError first actually, it helps. But I'll inline for now or create it quickly.
const User = require('../users/user.model');
const emailService = require('../../utils/email');
const jwt = require('jsonwebtoken');
const config = require('../../config/env');
const bcrypt = require('bcryptjs');

// Helper to generate 6 digit OTP
const generateOTP = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

const generateToken = (userId) => {
    const payload = {
        sub: userId,
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + (config.jwt.accessExpirationMinutes * 60),
    };
    return jwt.sign(payload, config.jwt.secret);
};

/**
 * Register a user
 * @param {Object} userBody
 * @returns {Promise<User>}
 */
const register = async (userBody) => {
    if (await User.isEmailTaken(userBody.email)) {
        throw new Error('Email already taken'); // StatusCode 400
    }

    const otp = generateOTP();
    const otpExpires = Date.now() + 10 * 60 * 1000; // 10 mins

    const user = await User.create({ ...userBody, otp, otpExpires, isVerified: false });

    await emailService.sendOTP(user.email, otp);

    return user;
};

/**
 * Verify Email with OTP
 * @param {string} email
 * @param {string} otp
 * @returns {Promise<User>}
 */
const verifyEmail = async (email, otp) => {
    const user = await User.findOne({ email });
    if (!user) {
        throw new Error('User not found');
    }

    if (user.isVerified) {
        return user;
    }

    if (user.otp !== otp || user.otpExpires < Date.now()) {
        throw new Error('Invalid or expired OTP');
    }

    user.isVerified = true;
    user.otp = undefined;
    user.otpExpires = undefined;
    await user.save();

    return user;
};

/**
 * Login with email and password
 * @param {string} email
 * @param {string} password
 * @returns {Promise<{user: User, token: string}>}
 */
const login = async (email, password) => {
    const user = await User.findOne({ email });
    if (!user || !(await user.isPasswordMatch(password))) {
        throw new Error('Incorrect email or password');
    }

    if (!user.isVerified) {
        throw new Error('Email not verified');
    }

    const token = generateToken(user.id);
    return { user, token };
};

/**
 * Forgot password - send OTP
 * @param {string} email
 */
const forgotPassword = async (email) => {
    const user = await User.findOne({ email });
    if (!user) {
        throw new Error('User not found');
    }

    const otp = generateOTP();
    user.otp = otp;
    user.otpExpires = Date.now() + 10 * 60 * 1000;
    await user.save();

    await emailService.sendOTP(user.email, otp);
};

/**
 * Reset password
 * @param {string} email
 * @param {string} otp
 * @param {string} newPassword
 */
const resetPassword = async (email, otp, newPassword) => {
    const user = await User.findOne({ email });
    if (!user) {
        throw new Error('User not found');
    }

    if (user.otp !== otp || user.otpExpires < Date.now()) {
        throw new Error('Invalid or expired OTP');
    }

    user.password = newPassword;
    user.otp = undefined;
    user.otpExpires = undefined;
    await user.save();
};

module.exports = {
    register,
    verifyEmail,
    login,
    forgotPassword,
    resetPassword,
};
