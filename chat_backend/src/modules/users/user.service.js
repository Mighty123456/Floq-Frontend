const httpStatus = require('http-status');
const User = require('./user.model');

/**
 * Get user by id
 * @param {ObjectId} id
 * @returns {Promise<User>}
 */
const getUserById = async (id) => {
    return User.findById(id);
};

/**
 * Get user by email
 * @param {string} email
 * @returns {Promise<User>}
 */
const getUserByEmail = async (email) => {
    return User.findOne({ email });
};

/**
 * Update user by id
 * @param {ObjectId} userId
 * @param {Object} updateBody
 * @returns {Promise<User>}
 */
const updateUserById = async (userId, updateBody) => {
    const user = await getUserById(userId);
    if (!user) {
        throw new Error('User not found');
    }
    if (updateBody.email && (await User.isEmailTaken(updateBody.email, userId))) {
        throw new Error('Email already taken');
    }
    Object.assign(user, updateBody);
    await user.save();
    return user;
};

/**
 * Search users
 * @param {string} query
 * @param {ObjectId} excludeUserId - User ID to exclude from results
 * @returns {Promise<User[]>}
 */
const searchUsers = async (query, excludeUserId = null) => {
    const searchQuery = {
        $or: [
            { name: { $regex: query, $options: 'i' } },
            { email: { $regex: query, $options: 'i' } }
        ],
    };
    
    if (excludeUserId) {
        searchQuery._id = { $ne: excludeUserId };
    }
    
    const users = await User.find(searchQuery).select('-password -otp -otpExpires');
    return users;
};

module.exports = {
    getUserById,
    getUserByEmail,
    updateUserById,
    searchUsers,
};
