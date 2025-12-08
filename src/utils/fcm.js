// utils/fcmTokenHandler.js

/**
 * Hàm xử lý đăng ký FCM token
 * @param {Object} user - Đối tượng user cần cập nhật token
 * @param {Object} payload - Object chứa thông tin token
 * @param {String} payload.fcmToken - FCM token từ client
 * @param {String} payload.deviceId - Device identifier
 * @param {String} payload.platform - Platform của thiết bị (android/ios)
 * @returns {Promise<boolean>} - Trả về true nếu xử lý thành công
 */
export const registerFCMToken = async (user, payload) => {
    try {
        const { fcmToken, deviceId, platform } = payload;

        if (!fcmToken || !deviceId || !platform) {
            console.warn('Thiếu thông tin bắt buộc để đăng ký FCM token:', {
                hasFcmToken: !!fcmToken,
                hasDeviceId: !!deviceId,
                hasPlatform: !!platform
            });
            return false;
        }

        if (!['android', 'ios'].includes(platform)) {
            console.warn('Platform không hợp lệ:', platform);
            return false;
        }

        await user.updateOne({
            $pull: { fcmTokens: { deviceId: deviceId } }
        });
        const tokenData = {
            token: fcmToken,
            deviceId: deviceId,
            platform: platform,
            lastUsed: new Date()
        };

        await user.updateOne({
            $push: { fcmTokens: tokenData }
        });

        return true;

    } catch (error) {
        console.error('Lỗi khi đăng ký FCM token:', error);
        return false;
    }
};
/**
 * Xóa FCM token khi user logout
 * @param {String} userId - User ID
 * @param {String} deviceId - Device ID cần xóa
 */
export const removeFCMToken = async (userId, deviceId) => {
    try {
        if (!deviceId) {
            console.warn('Device ID is required to remove FCM token');
            return false;
        }

        const user = await User.findById(userId);
        if (!user) {
            console.warn('User not found');
            return false;
        }

        const initialLength = user.fcmTokens.length;
        user.fcmTokens = user.fcmTokens.filter(t => t.deviceId !== deviceId);

        if (user.fcmTokens.length < initialLength) {
            await user.save();
            console.log(`✅ Removed FCM token for device ${deviceId}`);
            return true;
        } else {
            console.log(`⚠️ No FCM token found for device ${deviceId}`);
            return false;
        }

    } catch (error) {
        console.error('❌ Error removing FCM token:', error);
        return false;
    }
};

/**
 * Xóa các token không hợp lệ khỏi user
 * @param {String} userId - User ID
 * @param {Array} invalidTokens - Mảng các token không hợp lệ
 */
export const removeInvalidTokensFromUser = async (userId, invalidTokens) => {
    try {
        if (!invalidTokens || invalidTokens.length === 0) return;

        const user = await User.findById(userId);
        if (!user) return;

        const initialLength = user.fcmTokens.length;
        user.fcmTokens = user.fcmTokens.filter(
            t => !invalidTokens.includes(t.token)
        );

        if (user.fcmTokens.length < initialLength) {
            await user.save();
            console.log(`✅ Removed ${initialLength - user.fcmTokens.length} invalid FCM tokens`);
        }

    } catch (error) {
        console.error('❌ Error removing invalid FCM tokens:', error);
    }
};

/**
 * Update lastUsed cho token khi user active
 * @param {String} userId - User ID
 * @param {String} deviceId - Device ID
 */
export const updateTokenLastUsed = async (userId, deviceId) => {
    try {
        const user = await User.findById(userId);
        if (!user) return;

        const token = user.fcmTokens.find(t => t.deviceId === deviceId);
        if (token) {
            token.lastUsed = new Date();
            await user.save();
        }

    } catch (error) {
        console.error('❌ Error updating token lastUsed:', error);
    }
};