const authService = require('./auth.service');

const catchAsync = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((err) => next(err));
};

const register = catchAsync(async (req, res) => {
    const user = await authService.register(req.body);
    res.status(201).send({ message: 'Registration successful. OTP sent to email.', user });
});

const verifyEmail = catchAsync(async (req, res) => {
    await authService.verifyEmail(req.body.email, req.body.otp);
    res.status(200).send({ message: 'Email verified successfully' });
});

const login = catchAsync(async (req, res) => {
    const { email, password } = req.body;
    const { user, token } = await authService.login(email, password);
    res.send({ user, token });
});

const forgotPassword = catchAsync(async (req, res) => {
    await authService.forgotPassword(req.body.email);
    res.status(200).send({ message: 'OTP sent to email for password reset' });
});

const resetPassword = catchAsync(async (req, res) => {
    await authService.resetPassword(req.body.email, req.body.otp, req.body.newPassword);
    res.status(200).send({ message: 'Password reset successful' });
});

module.exports = {
    register,
    verifyEmail,
    login,
    forgotPassword,
    resetPassword,
};
